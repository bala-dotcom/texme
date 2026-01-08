<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\AdminLog;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class UserManagementController extends Controller
{
    /**
     * List all users with filters
     */
    public function index(Request $request): JsonResponse
    {
        $query = User::query();

        // Filters
        if ($request->has('user_type')) {
            $query->where('user_type', $request->user_type);
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('account_status')) {
            $query->where('account_status', $request->account_status);
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%")
                    ->orWhere('id', $search);
            });
        }

        // Sorting
        $sortBy = $request->get('sort_by', 'created_at');
        $sortOrder = $request->get('sort_order', 'desc');
        $query->orderBy($sortBy, $sortOrder);

        $users = $query->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'users' => $users->map(fn($u) => $this->formatUser($u)),
            'pagination' => [
                'current_page' => $users->currentPage(),
                'last_page' => $users->lastPage(),
                'per_page' => $users->perPage(),
                'total' => $users->total(),
            ],
        ]);
    }

    /**
     * Get single user details
     */
    public function show(int $id): JsonResponse
    {
        try {
            $user = User::find($id);

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not found',
                ], 404);
            }

            // Load counts separately to handle potential relationship issues gracefully
            $counts = ['chatsAsMale', 'chatsAsFemale', 'transactions', 'reportsMade', 'reportsReceived'];
            $existingRelationships = [];

            foreach ($counts as $relation) {
                if (method_exists($user, $relation)) {
                    $existingRelationships[] = $relation;
                }
            }

            if (!empty($existingRelationships)) {
                $user->loadCount($existingRelationships);
            }

            return response()->json([
                'success' => true,
                'user' => $this->formatUserDetails($user),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error loading user: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update user details
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $user = User::find($id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found',
            ], 404);
        }

        $request->validate([
            'name' => 'nullable|string|max:100',
            'phone' => 'nullable|string|max:15|unique:users,phone,' . $user->id,
            'age' => 'nullable|integer|min:18|max:100',
            'bio' => 'nullable|string|max:500',
            'earning_balance' => 'nullable|numeric|min:0',
            'coin_balance' => 'nullable|integer|min:0',
            // Bank details validation
            'bank_details' => 'nullable|array',
            'bank_details.account_name' => 'nullable|string|max:100',
            'bank_details.account_number' => 'nullable|string|max:30',
            'bank_details.ifsc' => 'nullable|string|size:11',
            'bank_details.bank_name' => 'nullable|string|max:100',
            'bank_details.upi_id' => 'nullable|string|max:50',
        ]);

        // Update basic info
        if ($request->has('name'))
            $user->name = $request->name;
        if ($request->has('phone'))
            $user->phone = $request->phone;
        if ($request->has('age'))
            $user->age = $request->age;
        if ($request->has('bio'))
            $user->bio = $request->bio;

        // Balances
        if ($request->has('coin_balance'))
            $user->coin_balance = $request->coin_balance;
        if ($request->has('earning_balance'))
            $user->earning_balance = $request->earning_balance;

        // Update bank details for females
        if ($user->isFemale() && $request->has('bank_details')) {
            $user->setBankDetails($request->bank_details);
        }

        $user->save();

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'user_update',
            'description' => "Updated user #{$id} details",
            'target_type' => 'user',
            'target_id' => $id,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'User details updated successfully',
            'user' => $this->formatUserDetails($user),
        ]);
    }

    /**
     * Update user status (approve/suspend/ban)
     */
    public function updateStatus(Request $request, int $id): JsonResponse
    {
        $request->validate([
            // Keep DB enum compatibility (pending|active|suspended)
            'account_status' => 'required|in:pending,active,suspended',
            'reason' => 'nullable|string|max:500',
        ]);

        $user = User::find($id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found',
            ], 404);
        }

        $oldStatus = $user->account_status;
        $user->account_status = $request->account_status;

        // If approving female, also verify
        if ($user->isFemale() && $request->account_status === 'active') {
            $user->is_verified = true;
        }

        $user->save();

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'user_status_update',
            'description' => "Changed user #{$id} status from {$oldStatus} to {$request->account_status}",
            'target_type' => 'user',
            'target_id' => $id,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'User status updated',
            'user' => $this->formatUser($user),
        ]);
    }

    /**
     * Get pending female approvals
     */
    public function pendingFemales(Request $request): JsonResponse
    {
        $females = User::where('user_type', 'female')
            ->where('account_status', 'pending')
            ->orderBy('created_at', 'asc')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'users' => $females->map(fn($u) => $this->formatUser($u)),
            'pagination' => [
                'current_page' => $females->currentPage(),
                'last_page' => $females->lastPage(),
                'total' => $females->total(),
            ],
        ]);
    }

    /**
     * Approve female user
     */
    public function approveFemale(Request $request, int $id): JsonResponse
    {
        $user = User::where('id', $id)
            ->where('user_type', 'female')
            ->where('account_status', 'pending')
            ->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found or not pending approval',
            ], 404);
        }

        $user->account_status = 'active';
        $user->is_verified = true;
        $user->save();

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'female_approval',
            'description' => "Approved female user #{$id}",
            'target_type' => 'user',
            'target_id' => $id,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'User approved successfully',
        ]);
    }

    /**
     * Reject female user
     */
    public function rejectFemale(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'reason' => 'required|string|max:500',
        ]);

        $user = User::where('id', $id)
            ->where('user_type', 'female')
            ->where('account_status', 'pending')
            ->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found or not pending approval',
            ], 404);
        }

        // Keep DB enum compatibility (pending|active|suspended)
        $user->account_status = 'suspended';
        $user->save();

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'female_rejection',
            'description' => "Rejected female user #{$id}: {$request->reason}",
            'target_type' => 'user',
            'target_id' => $id,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'User rejected',
        ]);
    }

    /**
     * Add coins to user (bonus/refund)
     */
    public function addCoins(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'coins' => 'required|integer',
            'reason' => 'required|string|max:200',
        ]);

        $user = User::where('id', $id)
            ->where('user_type', 'male')
            ->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Male user not found',
            ], 404);
        }

        $user->coin_balance += $request->coins;
        // Ensure balance doesn't go negative if that's preferred, but usually subtraction is fine.
        if ($user->coin_balance < 0) {
            $user->coin_balance = 0;
        }
        $user->save();

        $action = $request->coins > 0 ? "Added" : "Subtracted";
        $amount = abs($request->coins);

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'adjust_coins',
            'description' => "{$action} {$amount} coins from user #{$id}: {$request->reason}",
            'target_type' => 'user',
            'target_id' => $id,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => "Successfully updated user coins",
            'new_balance' => $user->coin_balance,
        ]);
    }

    // ========== HELPER METHODS ==========

    private function formatUser(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'phone' => $user->phone,
            'user_type' => $user->user_type,
            'avatar' => $user->avatar ? asset('storage/' . $user->avatar) : null,
            'status' => $user->status,
            'account_status' => $user->account_status,
            'is_verified' => $user->is_verified,
            'coin_balance' => $user->coin_balance,
            'earning_balance' => $user->earning_balance,
            'created_at' => $user->created_at,
            'last_seen' => $user->last_seen,
        ];
    }

    private function formatUserDetails(User $user): array
    {
        $data = $this->formatUser($user);

        $data['age'] = $user->age;
        $data['bio'] = $user->bio;
        $data['location'] = $user->location;
        $data['total_coins_purchased'] = $user->total_coins_purchased;
        $data['total_coins_spent'] = $user->total_coins_spent;
        $data['total_earned'] = $user->total_earned;
        $data['total_withdrawn'] = $user->total_withdrawn;
        $data['chats_as_male_count'] = $user->chats_as_male_count ?? 0;
        $data['chats_as_female_count'] = $user->chats_as_female_count ?? 0;
        $data['transactions_count'] = $user->transactions_count ?? 0;
        $data['reports_made_count'] = $user->reports_made_count ?? 0;
        $data['reports_received_count'] = $user->reports_received_count ?? 0;

        // Add bank details for female users
        if ($user->isFemale()) {
            $data['has_bank_details'] = !empty($user->bank_account_number);
            $data['bank_details'] = $user->getDecryptedBankDetails();
        }

        return $data;
    }
}
