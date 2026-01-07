<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Chat;
use App\Models\Transaction;
use App\Models\Withdrawal;
use App\Models\Report;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    /**
     * Get dashboard overview stats
     */
    public function overview(Request $request): JsonResponse
    {
        // User Stats
        $totalUsers = User::count();
        $maleUsers = User::where('user_type', 'male')->count();
        $femaleUsers = User::where('user_type', 'female')->count();
        $activeUsers = User::where('status', 'online')->count();
        $pendingFemales = User::where('user_type', 'female')
            ->where('account_status', 'pending')
            ->count();

        // Chat Stats
        $totalChats = Chat::count();
        $activeChats = Chat::where('status', 'active')->count();
        $todayChats = Chat::whereDate('created_at', today())->count();

        // Revenue Stats
        $totalRevenue = Transaction::where('type', 'coin_purchase')
            ->where('status', 'success')
            ->sum('amount');
        $todayRevenue = Transaction::where('type', 'coin_purchase')
            ->where('status', 'success')
            ->whereDate('created_at', today())
            ->sum('amount');
        $monthRevenue = Transaction::where('type', 'coin_purchase')
            ->where('status', 'success')
            ->whereMonth('created_at', now()->month)
            ->whereYear('created_at', now()->year)
            ->sum('amount');

        // Withdrawal Stats
        $pendingWithdrawals = Withdrawal::where('status', 'pending')->count();
        $pendingWithdrawalAmount = Withdrawal::where('status', 'pending')->sum('amount');
        $totalWithdrawn = Withdrawal::where('status', 'completed')->sum('amount');

        // Report Stats
        $pendingReports = Report::where('status', 'pending')->count();

        return response()->json([
            'success' => true,
            'stats' => [
                'users' => [
                    'total' => $totalUsers,
                    'male' => $maleUsers,
                    'female' => $femaleUsers,
                    'active' => $activeUsers,
                    'pending_females' => $pendingFemales,
                ],
                'chats' => [
                    'total' => $totalChats,
                    'active' => $activeChats,
                    'today' => $todayChats,
                ],
                'revenue' => [
                    'total' => round($totalRevenue, 2),
                    'today' => round($todayRevenue, 2),
                    'this_month' => round($monthRevenue, 2),
                ],
                'withdrawals' => [
                    'pending_count' => $pendingWithdrawals,
                    'pending_amount' => round($pendingWithdrawalAmount, 2),
                    'total_withdrawn' => round($totalWithdrawn, 2),
                ],
                'reports' => [
                    'pending' => $pendingReports,
                ],
            ],
        ]);
    }

    /**
     * Get revenue analytics (last 30 days)
     */
    public function revenueChart(Request $request): JsonResponse
    {
        $days = $request->get('days', 30);

        $revenue = Transaction::where('type', 'coin_purchase')
            ->where('status', 'success')
            ->where('created_at', '>=', now()->subDays($days))
            ->select(
                DB::raw('DATE(created_at) as date'),
                DB::raw('SUM(amount) as total')
            )
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        return response()->json([
            'success' => true,
            'chart' => $revenue,
        ]);
    }

    /**
     * Get user registration analytics
     */
    public function userChart(Request $request): JsonResponse
    {
        $days = $request->get('days', 30);

        $registrations = User::where('created_at', '>=', now()->subDays($days))
            ->select(
                DB::raw('DATE(created_at) as date'),
                DB::raw('user_type'),
                DB::raw('COUNT(*) as count')
            )
            ->groupBy('date', 'user_type')
            ->orderBy('date')
            ->get();

        return response()->json([
            'success' => true,
            'chart' => $registrations,
        ]);
    }

    /**
     * Get recent activities
     */
    public function recentActivities(Request $request): JsonResponse
    {
        $limit = $request->get('limit', 20);

        // Recent registrations
        $recentUsers = User::orderBy('created_at', 'desc')
            ->take(5)
            ->get(['id', 'name', 'user_type', 'created_at']);

        // Recent transactions
        $recentTransactions = Transaction::where('type', 'coin_purchase')
            ->where('status', 'success')
            ->orderBy('created_at', 'desc')
            ->take(5)
            ->with('user:id,name')
            ->get(['id', 'user_id', 'amount', 'coins', 'created_at']);

        // Recent withdrawals
        $recentWithdrawals = Withdrawal::orderBy('created_at', 'desc')
            ->take(5)
            ->with('user:id,name')
            ->get(['id', 'user_id', 'amount', 'status', 'created_at']);

        return response()->json([
            'success' => true,
            'activities' => [
                'recent_users' => $recentUsers,
                'recent_transactions' => $recentTransactions,
                'recent_withdrawals' => $recentWithdrawals,
            ],
        ]);
    }
}
