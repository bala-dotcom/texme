<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Report;
use App\Models\User;
use App\Models\AdminLog;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class ReportController extends Controller
{
    /**
     * List all reports with filters
     */
    public function index(Request $request): JsonResponse
    {
        $query = Report::with([
            'reporter:id,name,phone,user_type',
            'reportedUser:id,name,phone,user_type',
        ]);

        // Filters
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('reason')) {
            $query->where('reason', 'like', "%{$request->reason}%");
        }

        // Sorting
        $query->orderBy($request->get('sort_by', 'created_at'), $request->get('sort_order', 'desc'));

        $reports = $query->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'reports' => $reports->map(fn($r) => $this->formatReport($r)),
            'pagination' => [
                'current_page' => $reports->currentPage(),
                'last_page' => $reports->lastPage(),
                'total' => $reports->total(),
            ],
        ]);
    }

    /**
     * Get pending reports
     */
    public function pending(Request $request): JsonResponse
    {
        $reports = Report::with([
            'reporter:id,name,phone,user_type',
            'reportedUser:id,name,phone,user_type',
        ])
            ->where('status', 'pending')
            ->orderBy('created_at', 'asc')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'reports' => $reports->map(fn($r) => $this->formatReport($r)),
            'pagination' => [
                'current_page' => $reports->currentPage(),
                'last_page' => $reports->lastPage(),
                'total' => $reports->total(),
            ],
        ]);
    }

    /**
     * Get single report details
     */
    public function show(int $id): JsonResponse
    {
        $report = Report::with([
            'reporter:id,name,phone,user_type,avatar',
            'reportedUser:id,name,phone,user_type,avatar,account_status',
            'chat',
        ])->find($id);

        if (!$report) {
            return response()->json([
                'success' => false,
                'message' => 'Report not found',
            ], 404);
        }

        // Get reported user's report history
        $reportHistory = Report::where('reported_user', $report->reported_user)
            ->where('id', '!=', $id)
            ->count();

        return response()->json([
            'success' => true,
            'report' => $this->formatReportDetails($report),
            'reported_user_history' => [
                'previous_reports' => $reportHistory,
            ],
        ]);
    }

    /**
     * Resolve report - dismiss
     */
    public function dismiss(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'notes' => 'nullable|string|max:500',
        ]);

        $report = Report::where('id', $id)
            ->where('status', 'pending')
            ->first();

        if (!$report) {
            return response()->json([
                'success' => false,
                'message' => 'Report not found or already resolved',
            ], 404);
        }

        $report->status = 'dismissed';
        $report->resolved_by = $request->user()->id;
        $report->resolved_at = now();
        $report->admin_notes = $request->notes;
        $report->save();

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'report_dismiss',
            'description' => "Dismissed report #{$id}",
            'target_type' => 'report',
            'target_id' => $id,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Report dismissed',
        ]);
    }

    /**
     * Resolve report with warning to user
     */
    public function warn(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'notes' => 'required|string|max:500',
        ]);

        $report = Report::where('id', $id)
            ->where('status', 'pending')
            ->first();

        if (!$report) {
            return response()->json([
                'success' => false,
                'message' => 'Report not found or already resolved',
            ], 404);
        }

        $report->status = 'resolved';
        $report->action_taken = 'warning';
        $report->resolved_by = $request->user()->id;
        $report->resolved_at = now();
        $report->admin_notes = $request->notes;
        $report->save();

        // TODO: Send warning notification to user

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'report_warn',
            'description' => "Warned user #{$report->reported_user} for report #{$id}",
            'target_type' => 'report',
            'target_id' => $id,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Warning issued to user',
        ]);
    }

    /**
     * Resolve report with user suspension
     */
    public function suspend(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'days' => 'required|integer|min:1|max:365',
            'notes' => 'required|string|max:500',
        ]);

        $report = Report::where('id', $id)
            ->where('status', 'pending')
            ->first();

        if (!$report) {
            return response()->json([
                'success' => false,
                'message' => 'Report not found or already resolved',
            ], 404);
        }

        // Suspend user
        $user = User::find($report->reported_user);
        if ($user) {
            $user->account_status = 'suspended';
            $user->save();
        }

        $report->status = 'resolved';
        $report->action_taken = 'suspension';
        $report->resolved_by = $request->user()->id;
        $report->resolved_at = now();
        $report->admin_notes = "{$request->days} day suspension. {$request->notes}";
        $report->save();

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'report_suspend',
            'description' => "Suspended user #{$report->reported_user} for {$request->days} days",
            'target_type' => 'report',
            'target_id' => $id,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => "User suspended for {$request->days} days",
        ]);
    }

    /**
     * Resolve report with permanent ban
     */
    public function ban(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'notes' => 'required|string|max:500',
        ]);

        $report = Report::where('id', $id)
            ->where('status', 'pending')
            ->first();

        if (!$report) {
            return response()->json([
                'success' => false,
                'message' => 'Report not found or already resolved',
            ], 404);
        }

        // Ban user
        $user = User::find($report->reported_user);
        if ($user) {
            // Keep DB enum compatibility (pending|active|suspended)
            $user->account_status = 'suspended';
            $user->save();
        }

        $report->status = 'resolved';
        $report->action_taken = 'ban';
        $report->resolved_by = $request->user()->id;
        $report->resolved_at = now();
        $report->admin_notes = "Permanent ban. {$request->notes}";
        $report->save();

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'report_ban',
            'description' => "Permanently banned user #{$report->reported_user}",
            'target_type' => 'report',
            'target_id' => $id,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'User permanently banned',
        ]);
    }

    // ========== HELPER METHODS ==========

    private function formatReport(Report $r): array
    {
        return [
            'id' => $r->id,
            'reporter' => [
                'id' => $r->reporter?->id,
                'name' => $r->reporter?->name,
                'user_type' => $r->reporter?->user_type,
            ],
            'reported_user' => [
                'id' => $r->reportedUser?->id,
                'name' => $r->reportedUser?->name,
                'user_type' => $r->reportedUser?->user_type,
            ],
            'reason' => $r->reason,
            'description' => $r->description,
            'status' => $r->status,
            'created_at' => $r->created_at,
        ];
    }

    private function formatReportDetails(Report $r): array
    {
        $data = $this->formatReport($r);
        
        $data['chat_id'] = $r->chat_id;
        $data['action_taken'] = $r->action_taken;
        $data['admin_notes'] = $r->admin_notes;
        $data['resolved_by'] = $r->resolved_by;
        $data['resolved_at'] = $r->resolved_at;

        return $data;
    }
}
