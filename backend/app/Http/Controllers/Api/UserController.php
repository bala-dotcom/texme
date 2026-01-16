<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Report;
use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class UserController extends Controller
{
    /**
     * List available females (for male users)
     */
    public function listFemales(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isMale()) {
            return response()->json([
                'success' => false,
                'message' => 'Only male users can browse females',
            ], 403);
        }

        $females = User::where('user_type', 'female')
            ->where('account_status', 'active')
            ->where('id', '!=', $user->id)
            ->orderByRaw("CASE WHEN status = 'online' THEN 0 ELSE 1 END")
            ->orderBy('last_seen', 'desc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'users' => $females->map(fn($f) => $this->formatFemaleForMale($f)),
            'pagination' => [
                'current_page' => $females->currentPage(),
                'last_page' => $females->lastPage(),
                'total' => $females->total(),
            ],
        ]);
    }

    /**
     * List males with potential earnings (for female users)
     */
    public function listMales(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isFemale()) {
            return response()->json([
                'success' => false,
                'message' => 'Only female users can view this',
            ], 403);
        }

        $males = User::where('user_type', 'male')
            ->where('account_status', 'active')
            ->where('coin_balance', '>', 0)
            ->where('status', 'online')
            ->orderBy('coin_balance', 'desc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'users' => $males->map(fn($m) => $this->formatMaleForFemale($m)),
            'pagination' => [
                'current_page' => $males->currentPage(),
                'last_page' => $males->lastPage(),
                'total' => $males->total(),
            ],
        ]);
    }

    /**
     * Get random available female (for random connect)
     */
    public function randomFemale(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isMale()) {
            return response()->json([
                'success' => false,
                'message' => 'Only male users can use random connect',
            ], 403);
        }

        if ($user->coin_balance < Setting::getCoinsPerMinute()) {
            return response()->json([
                'success' => false,
                'message' => 'Not enough coins for chat',
            ], 400);
        }

        $female = User::where('user_type', 'female')
            ->where('account_status', 'active')
            ->where('is_verified', true)
            ->where('status', 'online')
            ->inRandomOrder()
            ->first();

        if (!$female) {
            return response()->json([
                'success' => false,
                'message' => 'No females available right now. Please try again later.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'user' => $this->formatFemaleForMale($female),
        ]);
    }

    /**
     * Get user by ID
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $currentUser = $request->user();

        $user = User::where('id', $id)
            ->where('account_status', 'active')
            ->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User not found',
            ], 404);
        }

        if ($currentUser->isMale() && $user->isFemale()) {
            return response()->json([
                'success' => true,
                'user' => $this->formatFemaleForMale($user),
            ]);
        }

        if ($currentUser->isFemale() && $user->isMale()) {
            return response()->json([
                'success' => true,
                'user' => $this->formatMaleForFemale($user),
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Cannot view this user',
        ], 403);
    }

    /**
     * Get bank details (female only)
     */
    public function getBankDetails(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isFemale()) {
            return response()->json([
                'success' => false,
                'message' => 'Only female users can access bank details',
            ], 403);
        }

        $bankDetails = $user->getDecryptedBankDetails();
        $hasBankDetails = !empty($user->bank_account_number);

        return response()->json([
            'success' => true,
            'has_bank_details' => $hasBankDetails,
            'bank_details' => $hasBankDetails ? $bankDetails : null,
        ]);
    }

    /**
     * Update bank details (female only)
     */
    public function updateBankDetails(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isFemale()) {
            return response()->json([
                'success' => false,
                'message' => 'Only female users can add bank details',
            ], 403);
        }

        $request->validate([
            'account_name' => 'required|string|max:100',
            'account_number' => 'required|string|max:20',
            'ifsc' => 'required|string|size:11',
            'bank_name' => 'required|string|max:100',
            'upi_id' => 'nullable|string|max:50',
        ]);

        $user->setBankDetails([
            'account_name' => $request->account_name,
            'account_number' => $request->account_number,
            'ifsc' => $request->ifsc,
            'bank_name' => $request->bank_name,
            'upi_id' => $request->upi_id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Bank details updated successfully',
        ]);
    }

    /**
     * Report a user
     */
    public function reportUser(Request $request): JsonResponse
    {
        $request->validate([
            'user_id' => 'required|exists:users,id',
            'reason' => 'required|string|max:100',
            'description' => 'nullable|string|max:500',
            'chat_id' => 'nullable|exists:chats,id',
        ]);

        Report::create([
            'reported_by' => $request->user()->id,
            'reported_user' => $request->user_id,
            'chat_id' => $request->chat_id,
            'reason' => $request->reason,
            'description' => $request->description,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Report submitted. We will review it shortly.',
        ]);
    }

    /**
     * Get app settings
     */
    public function appSettings(Request $request): JsonResponse
    {
        $user = $request->user();

        $settings = [
            'coins_per_minute' => Setting::getCoinsPerMinute(),
            'min_withdrawal' => Setting::getMinWithdrawal(),
        ];

        if ($user->isMale()) {
            $settings['coin_packages'] = Setting::getCoinPackages();
        }

        if ($user->isFemale()) {
            $settings['earning_ratio'] = Setting::getFemaleEarningRatio();
        }

        return response()->json([
            'success' => true,
            'settings' => $settings,
        ]);
    }

    /**
     * Format female user data for male view
     */
    private function formatFemaleForMale(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'age' => $user->age,
            'bio' => $user->bio,
            'avatar' => $user->avatar ? (str_starts_with($user->avatar, 'http') ? $user->avatar : asset('storage/' . $user->avatar)) : null,
            'location' => $user->location,
            'status' => $user->status,
            'is_available' => $user->status === 'online',
            'rate_per_minute' => $user->rate_per_minute,
        ];
    }

    /**
     * Format male user data for female view (with potential earnings)
     */
    private function formatMaleForFemale(User $user): array
    {
        $coinsPerMinute = Setting::getCoinsPerMinute();
        $earningRatio = Setting::getFemaleEarningRatio();

        // Calculate potential earnings
        $possibleMinutes = floor($user->coin_balance / $coinsPerMinute);
        $coinValue = 0.625; // ₹25 = 40 coins, so 1 coin = ₹0.625
        $potentialEarning = round($user->coin_balance * $coinValue * $earningRatio, 2);

        return [
            'id' => $user->id,
            'status' => $user->status,
            'coin_balance' => $user->coin_balance,
            'possible_minutes' => $possibleMinutes,
            'potential_earning' => $potentialEarning,
            'potential_earning_formatted' => '₹' . number_format($potentialEarning, 0),
        ];
    }
}
