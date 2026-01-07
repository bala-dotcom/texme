<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class TransactionController extends Controller
{
    /**
     * List all transactions with filters
     */
    public function index(Request $request): JsonResponse
    {
        $query = Transaction::with('user:id,name,phone,user_type');

        // Filters
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

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

        $transactions = $query->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'transactions' => $transactions->map(fn($t) => $this->formatTransaction($t)),
            'pagination' => [
                'current_page' => $transactions->currentPage(),
                'last_page' => $transactions->lastPage(),
                'total' => $transactions->total(),
            ],
        ]);
    }

    /**
     * Get transaction summary/stats
     */
    public function summary(Request $request): JsonResponse
    {
        $fromDate = $request->get('from_date', now()->startOfMonth());
        $toDate = $request->get('to_date', now());

        // Revenue (coin purchases)
        $revenue = Transaction::where('type', 'coin_purchase')
            ->where('status', 'success')
            ->whereBetween('created_at', [$fromDate, $toDate])
            ->sum('amount');

        // Coins sold
        $coinsSold = Transaction::where('type', 'coin_purchase')
            ->where('status', 'success')
            ->whereBetween('created_at', [$fromDate, $toDate])
            ->sum('coins');

        // Coins spent on chats
        $coinsSpent = Transaction::where('type', 'coin_deduction')
            ->whereBetween('created_at', [$fromDate, $toDate])
            ->sum('coins');

        // Earnings distributed
        $earnings = Transaction::where('type', 'earning')
            ->whereBetween('created_at', [$fromDate, $toDate])
            ->sum('amount');

        // Withdrawals
        $withdrawals = Transaction::where('type', 'withdrawal')
            ->where('status', 'success')
            ->whereBetween('created_at', [$fromDate, $toDate])
            ->sum('amount');

        // By type breakdown
        $byType = Transaction::where('status', 'success')
            ->whereBetween('created_at', [$fromDate, $toDate])
            ->select('type', DB::raw('COUNT(*) as count'), DB::raw('SUM(amount) as total'))
            ->groupBy('type')
            ->get();

        return response()->json([
            'success' => true,
            'summary' => [
                'period' => [
                    'from' => $fromDate,
                    'to' => $toDate,
                ],
                'revenue' => round($revenue, 2),
                'coins_sold' => $coinsSold,
                'coins_spent' => abs($coinsSpent),
                'earnings_distributed' => round($earnings, 2),
                'withdrawals_paid' => round($withdrawals, 2),
                'profit' => round($revenue - $withdrawals, 2),
                'by_type' => $byType,
            ],
        ]);
    }

    /**
     * Get single transaction details
     */
    public function show(int $id): JsonResponse
    {
        $transaction = Transaction::with('user')->find($id);

        if (!$transaction) {
            return response()->json([
                'success' => false,
                'message' => 'Transaction not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'transaction' => [
                'id' => $transaction->id,
                'user' => [
                    'id' => $transaction->user?->id,
                    'name' => $transaction->user?->name,
                    'phone' => $transaction->user?->phone,
                    'user_type' => $transaction->user?->user_type,
                ],
                'type' => $transaction->type,
                'amount' => $transaction->amount,
                'coins' => $transaction->coins,
                'status' => $transaction->status,
                'gateway' => $transaction->gateway,
                'gateway_order_id' => $transaction->gateway_order_id,
                'gateway_payment_id' => $transaction->gateway_payment_id,
                'chat_id' => $transaction->chat_id,
                'chat_minutes' => $transaction->chat_minutes,
                'metadata' => $transaction->metadata,
                'created_at' => $transaction->created_at,
            ],
        ]);
    }

    /**
     * Export transactions to CSV
     */
    public function export(Request $request): JsonResponse
    {
        $query = Transaction::with('user:id,name,phone')
            ->where('status', 'success');

        // Date range
        if ($request->has('from_date')) {
            $query->whereDate('created_at', '>=', $request->from_date);
        }
        if ($request->has('to_date')) {
            $query->whereDate('created_at', '<=', $request->to_date);
        }

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        $transactions = $query->orderBy('created_at', 'desc')->get();

        // Generate CSV data
        $csvData = [];
        $csvData[] = ['ID', 'Date', 'User', 'Phone', 'Type', 'Amount', 'Coins', 'Status', 'Gateway'];

        foreach ($transactions as $t) {
            $csvData[] = [
                $t->id,
                $t->created_at->format('Y-m-d H:i:s'),
                $t->user?->name,
                $t->user?->phone,
                $t->type,
                $t->amount,
                $t->coins,
                $t->status,
                $t->gateway,
            ];
        }

        return response()->json([
            'success' => true,
            'csv' => $csvData,
            'count' => count($transactions),
        ]);
    }

    // ========== HELPER METHODS ==========

    private function formatTransaction(Transaction $t): array
    {
        return [
            'id' => $t->id,
            'user_id' => $t->user_id,
            'user_name' => $t->user?->name,
            'user_type' => $t->user?->user_type,
            'type' => $t->type,
            'amount' => $t->amount,
            'coins' => $t->coins,
            'status' => $t->status,
            'gateway' => $t->gateway,
            'created_at' => $t->created_at,
        ];
    }
}
