<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Transaction;
use App\Models\Withdrawal;
use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class WalletController extends Controller
{
    /**
     * Get wallet balance (female only)
     */
    public function balance(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isFemale()) {
            return response()->json([
                'success' => false,
                'message' => 'This feature is for female users only',
            ], 403);
        }

        // First withdrawal is ₹10, subsequent withdrawals are ₹50
        $isFirstWithdrawal = $user->total_withdrawn == 0;
        $minWithdrawal = $isFirstWithdrawal ? 10 : 50;

        return response()->json([
            'success' => true,
            'balance' => $user->earning_balance,
            'total_earned' => $user->total_earned,
            'total_withdrawn' => $user->total_withdrawn,
            'rate_per_minute' => $user->rate_per_minute,
            'min_withdrawal' => $minWithdrawal,
            'is_first_withdrawal' => $isFirstWithdrawal,
            'has_bank_details' => !empty($user->bank_account_number),
        ]);
    }

    /**
     * Get withdrawal history (for wallet page - only withdrawals)
     */
    public function history(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isFemale()) {
            return response()->json([
                'success' => false,
                'message' => 'This feature is for female users only',
            ], 403);
        }

        // Only show withdrawal transactions on wallet page
        $transactions = Transaction::where('user_id', $user->id)
            ->where('type', 'withdrawal')
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'transactions' => $transactions->map(fn($t) => [
                'id' => $t->id,
                'type' => $t->type,
                'amount' => $t->amount,
                'status' => $t->status,
                'description' => 'Withdrawal',
                'created_at' => $t->created_at,
            ]),
            'pagination' => [
                'current_page' => $transactions->currentPage(),
                'last_page' => $transactions->lastPage(),
                'total' => $transactions->total(),
            ],
        ]);
    }

    /**
     * Get all transaction history (earnings + withdrawals)
     */
    public function earningHistory(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isFemale()) {
            return response()->json([
                'success' => false,
                'message' => 'This feature is for female users only',
            ], 403);
        }

        // Show all transactions (earnings + withdrawals)
        $transactions = Transaction::where('user_id', $user->id)
            ->whereIn('type', ['earning', 'withdrawal'])
            ->orderBy('created_at', 'desc')
            ->with('chat:id,total_minutes')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'transactions' => $transactions->map(function ($t) {
                // Get partner name for earnings
                $partnerName = null;
                $description = '';

                if ($t->type === 'earning') {
                    $partnerUserId = $t->metadata['partner_user_id'] ?? null;
                    if ($partnerUserId) {
                        $partner = User::find($partnerUserId);
                        $partnerName = $partner ? $partner->name : null;
                    }
                    $description = $partnerName ? "Chat with $partnerName" : 'Chat earning';
                } else if ($t->type === 'withdrawal') {
                    $description = 'Withdrawal';
                }

                return [
                    'id' => $t->id,
                    'type' => $t->type,
                    'amount' => $t->amount,
                    'chat_minutes' => $t->chat?->total_minutes,
                    'status' => $t->status,
                    'description' => $description,
                    'partner_name' => $partnerName,
                    'created_at' => $t->created_at,
                ];
            }),
            'pagination' => [
                'current_page' => $transactions->currentPage(),
                'last_page' => $transactions->lastPage(),
                'total' => $transactions->total(),
            ],
        ]);
    }

    /**
     * Request withdrawal
     */
    public function requestWithdrawal(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isFemale()) {
            return response()->json([
                'success' => false,
                'message' => 'This feature is for female users only',
            ], 403);
        }

        $request->validate([
            'amount' => 'required|numeric|min:1',
        ]);

        $amount = $request->amount;

        // First withdrawal is ₹10, subsequent withdrawals are ₹50
        $isFirstWithdrawal = $user->total_withdrawn == 0;
        $minWithdrawal = $isFirstWithdrawal ? 10 : 50;

        if ($amount < $minWithdrawal) {
            $message = $isFirstWithdrawal
                ? "Minimum withdrawal for first time is ₹{$minWithdrawal}"
                : "Minimum withdrawal amount is ₹{$minWithdrawal}";
            return response()->json([
                'success' => false,
                'message' => $message,
            ], 400);
        }

        if ($amount > $user->earning_balance) {
            return response()->json([
                'success' => false,
                'message' => 'Insufficient balance',
                'available_balance' => $user->earning_balance,
            ], 400);
        }

        // Check if bank details exist
        if (empty($user->bank_account_number)) {
            return response()->json([
                'success' => false,
                'message' => 'Please add bank details first',
            ], 400);
        }

        // Check for pending withdrawal
        $pendingWithdrawal = Withdrawal::where('user_id', $user->id)
            ->whereIn('status', ['pending', 'processing'])
            ->exists();

        if ($pendingWithdrawal) {
            return response()->json([
                'success' => false,
                'message' => 'You already have a pending withdrawal request',
            ], 400);
        }

        // Create withdrawal request
        $withdrawal = Withdrawal::create([
            'user_id' => $user->id,
            'amount' => $amount,
            'bank_details' => $user->getDecryptedBankDetails(),
            'status' => 'pending',
        ]);

        // Create transaction record
        Transaction::create([
            'user_id' => $user->id,
            'type' => 'withdrawal',
            'amount' => $amount,
            'status' => 'pending',
        ]);

        // Deduct balance from user's account
        $user->earning_balance -= $amount;
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Withdrawal request submitted. Processing time: 2-3 business days.',
            'withdrawal_id' => $withdrawal->id,
            'new_balance' => $user->earning_balance,
        ]);
    }

    /**
     * Get withdrawal history
     */
    public function withdrawalHistory(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isFemale()) {
            return response()->json([
                'success' => false,
                'message' => 'This feature is for female users only',
            ], 403);
        }

        $withdrawals = Withdrawal::where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'withdrawals' => $withdrawals->map(fn($w) => [
                'id' => $w->id,
                'amount' => $w->amount,
                'status' => $w->status,
                'bank_name' => $w->bank_details['bank_name'] ?? null,
                'account_last_4' => isset($w->bank_details['account_number'])
                    ? '****' . substr($w->bank_details['account_number'], -4)
                    : null,
                'requested_at' => $w->created_at,
                'processed_at' => $w->processed_at,
            ]),
            'pagination' => [
                'current_page' => $withdrawals->currentPage(),
                'last_page' => $withdrawals->lastPage(),
                'total' => $withdrawals->total(),
            ],
        ]);
    }
}
