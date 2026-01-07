<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Withdrawal;
use App\Models\User;
use App\Models\Transaction;
use App\Models\AdminLog;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class WithdrawalController extends Controller
{
    /**
     * List all withdrawals with filters
     */
    public function index(Request $request): JsonResponse
    {
        $query = Withdrawal::with('user:id,name,phone');

        // Filters
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        // Date range
        if ($request->has('from_date')) {
            $query->whereDate('created_at', '>=', $request->from_date);
        }
        if ($request->has('to_date')) {
            $query->whereDate('created_at', '<=', $request->to_date);
        }

        // Sorting
        $query->orderBy($request->get('sort_by', 'created_at'), $request->get('sort_order', 'desc'));

        $withdrawals = $query->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'withdrawals' => $withdrawals->map(fn($w) => $this->formatWithdrawal($w)),
            'pagination' => [
                'current_page' => $withdrawals->currentPage(),
                'last_page' => $withdrawals->lastPage(),
                'total' => $withdrawals->total(),
            ],
        ]);
    }

    /**
     * Get pending withdrawals
     */
    public function pending(Request $request): JsonResponse
    {
        $withdrawals = Withdrawal::with('user:id,name,phone')
            ->where('status', 'pending')
            ->orderBy('created_at', 'asc')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'withdrawals' => $withdrawals->map(fn($w) => $this->formatWithdrawal($w)),
            'pagination' => [
                'current_page' => $withdrawals->currentPage(),
                'last_page' => $withdrawals->lastPage(),
                'total' => $withdrawals->total(),
            ],
            'summary' => [
                'total_pending' => Withdrawal::where('status', 'pending')->sum('amount'),
                'total_count' => Withdrawal::where('status', 'pending')->count(),
            ],
        ]);
    }

    /**
     * Get single withdrawal details
     */
    public function show(int $id): JsonResponse
    {
        $withdrawal = Withdrawal::with('user')->find($id);

        if (!$withdrawal) {
            return response()->json([
                'success' => false,
                'message' => 'Withdrawal not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'withdrawal' => $this->formatWithdrawalDetails($withdrawal),
        ]);
    }

    /**
     * Approve withdrawal
     */
    public function approve(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'transaction_id' => 'nullable|string|max:100',
            'notes' => 'nullable|string|max:500',
        ]);

        $withdrawal = Withdrawal::where('id', $id)
            ->where('status', 'pending')
            ->first();

        if (!$withdrawal) {
            return response()->json([
                'success' => false,
                'message' => 'Withdrawal not found or already processed',
            ], 404);
        }

        DB::transaction(function () use ($withdrawal, $request) {
            // Update withdrawal status
            $withdrawal->status = 'processing';
            $withdrawal->processed_at = now();
            $withdrawal->processed_by = $request->user()->id;
            $withdrawal->admin_notes = $request->notes;
            $withdrawal->save();

            // Deduct from user balance
            $user = $withdrawal->user;
            $user->earning_balance -= $withdrawal->amount;
            $user->total_withdrawn += $withdrawal->amount;
            $user->save();

            // Update related transaction
            Transaction::where('user_id', $user->id)
                ->where('type', 'withdrawal')
                ->where('status', 'pending')
                ->where('amount', $withdrawal->amount)
                ->update(['status' => 'processing']);
        });

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'withdrawal_approve',
            'description' => "Approved withdrawal #{$id} for ₹{$withdrawal->amount}",
            'target_type' => 'withdrawal',
            'target_id' => $id,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Withdrawal approved and processing',
        ]);
    }

    /**
     * Mark withdrawal as completed
     */
    public function complete(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'transaction_id' => 'required|string|max:100',
        ]);

        $withdrawal = Withdrawal::where('id', $id)
            ->whereIn('status', ['pending', 'processing'])
            ->first();

        if (!$withdrawal) {
            return response()->json([
                'success' => false,
                'message' => 'Withdrawal not found or already completed',
            ], 404);
        }

        DB::transaction(function () use ($withdrawal, $request) {
            // If still pending, deduct balance first
            if ($withdrawal->status === 'pending') {
                $user = $withdrawal->user;
                $user->earning_balance -= $withdrawal->amount;
                $user->total_withdrawn += $withdrawal->amount;
                $user->save();
            }

            $withdrawal->status = 'completed';
            $withdrawal->processed_at = now();
            $withdrawal->processed_by = $request->user()->id;
            $withdrawal->gateway_transaction_id = $request->transaction_id;
            $withdrawal->save();

            // Update related transaction
            Transaction::where('user_id', $withdrawal->user_id)
                ->where('type', 'withdrawal')
                ->whereIn('status', ['pending', 'processing'])
                ->where('amount', $withdrawal->amount)
                ->update(['status' => 'success']);
        });

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'withdrawal_complete',
            'description' => "Completed withdrawal #{$id} with txn: {$request->transaction_id}",
            'target_type' => 'withdrawal',
            'target_id' => $id,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Withdrawal completed successfully',
        ]);
    }

    /**
     * Reject withdrawal
     */
    public function reject(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'reason' => 'required|string|max:500',
        ]);

        $withdrawal = Withdrawal::where('id', $id)
            ->whereIn('status', ['pending', 'processing'])
            ->first();

        if (!$withdrawal) {
            return response()->json([
                'success' => false,
                'message' => 'Withdrawal not found or already processed',
            ], 404);
        }

        DB::transaction(function () use ($withdrawal, $request) {
            // If was processing, refund the balance
            if ($withdrawal->status === 'processing') {
                $user = $withdrawal->user;
                $user->earning_balance += $withdrawal->amount;
                $user->total_withdrawn -= $withdrawal->amount;
                $user->save();
            }

            $withdrawal->status = 'rejected';
            $withdrawal->processed_at = now();
            $withdrawal->processed_by = $request->user()->id;
            $withdrawal->admin_notes = $request->reason;
            $withdrawal->save();

            // Update related transaction
            Transaction::where('user_id', $withdrawal->user_id)
                ->where('type', 'withdrawal')
                ->whereIn('status', ['pending', 'processing'])
                ->where('amount', $withdrawal->amount)
                ->update(['status' => 'failed']);
        });

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'withdrawal_reject',
            'description' => "Rejected withdrawal #{$id}: {$request->reason}",
            'target_type' => 'withdrawal',
            'target_id' => $id,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Withdrawal rejected',
        ]);
    }

    // ========== HELPER METHODS ==========

    private function formatWithdrawal(Withdrawal $w): array
    {
        return [
            'id' => $w->id,
            'user_id' => $w->user_id,
            'user_name' => $w->user?->name,
            'user_phone' => $w->user?->phone,
            'amount' => $w->amount,
            'status' => $w->status,
            'bank_name' => $w->bank_details['bank_name'] ?? null,
            'account_last_4' => isset($w->bank_details['account_number'])
                ? '****' . substr($w->bank_details['account_number'], -4)
                : null,
            'created_at' => $w->created_at,
            'processed_at' => $w->processed_at,
        ];
    }

    private function formatWithdrawalDetails(Withdrawal $w): array
    {
        $data = $this->formatWithdrawal($w);
        
        $data['bank_details'] = [
            'account_name' => $w->bank_details['account_name'] ?? null,
            'account_number' => $w->bank_details['account_number'] ?? null,
            'ifsc' => $w->bank_details['ifsc'] ?? null,
            'bank_name' => $w->bank_details['bank_name'] ?? null,
            'upi_id' => $w->bank_details['upi_id'] ?? null,
        ];
        $data['admin_notes'] = $w->admin_notes;
        $data['gateway_transaction_id'] = $w->gateway_transaction_id;
        $data['processed_by'] = $w->processed_by;

        return $data;
    }
}
