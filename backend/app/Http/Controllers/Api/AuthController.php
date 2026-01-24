<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\OtpVerification;
use App\Services\OtpService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    protected OtpService $otpService;

    public function __construct(OtpService $otpService)
    {
        $this->otpService = $otpService;
    }

    /**
     * Send OTP to phone number
     */
    public function sendOtp(Request $request): JsonResponse
    {
        $request->validate([
            'phone' => 'required|string|regex:/^[6-9]\d{9}$/',
        ]);

        $phone = $request->phone;

        // Generate OTP
        $otpRecord = OtpVerification::generateForPhone($phone);

        // Send OTP via MSG91 or other provider
        $sent = $this->otpService->send($phone, $otpRecord->otp);

        if (!$sent) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to send OTP. Please try again.',
            ], 500);
        }

        // Check if user already exists
        $userExists = User::where('phone', $phone)->exists();

        return response()->json([
            'success' => true,
            'message' => 'OTP sent successfully',
            'is_existing_user' => $userExists,
            'expires_in' => 600, // 10 minutes
        ]);
    }

    /**
     * Verify OTP and login/register
     */
    public function verifyOtp(Request $request): JsonResponse
    {
        $request->validate([
            'phone' => 'nullable|string',
            'otp' => 'nullable|string',
            'access_token' => 'nullable|string',
        ]);

        $phone = $request->phone;
        $otp = $request->otp;
        $accessToken = $request->access_token;

        // 1. Verify OTP
        if ($accessToken) {
            // MSG91 Widget flow
            $verifiedPhone = $this->otpService->verifyMsg91Token($accessToken);

            if (!$verifiedPhone) {
                return response()->json([
                    'success' => false,
                    'message' => 'OTP verification failed with MSG91.',
                ], 400);
            }

            // Normalize phone number (MSG91 returns with country code 91...)
            if (str_starts_with($verifiedPhone, '91') && strlen($verifiedPhone) === 12) {
                $phone = substr($verifiedPhone, 2);
            } else {
                $phone = $verifiedPhone;
            }
        } else {
            // Legacy flow (for testing/development)
            if (!$phone || !$otp) {
                return response()->json([
                    'success' => false,
                    'message' => 'Phone and OTP are required.',
                ], 400);
            }

            // Find OTP record
            $otpRecord = OtpVerification::where('phone', $phone)
                ->where('is_verified', false)
                ->latest()
                ->first();

            // Verify OTP - Allow test OTP "011011" always (master bypass)
            $isTestOtp = $otp === '011011';

            if (!$isTestOtp) {
                // Try local verification first
                $verifiedLocally = $otpRecord && $otpRecord->verify($otp);

                if (!$verifiedLocally) {
                    // Fallback to OTP provider's own verification (for MSG91 Widget flow)
                    $verifiedByProvider = $this->otpService->verify($phone, $otp);

                    if (!$verifiedByProvider) {
                        return response()->json([
                            'success' => false,
                            'message' => 'Invalid OTP. Please try again.',
                        ], 400);
                    }
                }
            } else if ($otpRecord) {
                $otpRecord->is_verified = true;
                $otpRecord->save();
            }
        }

        // 2. Login or prepare Register response
        $user = User::where('phone', $phone)->first();

        if ($user) {
            // Existing user - login
            $user->status = 'online';
            $user->last_seen = now();
            $user->save();

            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'Login successful',
                'is_new_user' => false,
                'user' => $this->formatUserResponse($user),
                'token' => $token,
            ]);
        }

        // New user - needs to complete registration
        return response()->json([
            'success' => true,
            'message' => 'Phone verified. Please complete registration.',
            'is_new_user' => true,
            'phone' => $phone,
            'registration_token' => encrypt($phone . '|' . now()->timestamp),
        ]);
    }

    /**
     * Verify using Truecaller OAuth
     */
    public function truecallerVerify(Request $request): JsonResponse
    {
        $request->validate([
            'authorization_code' => 'required|string',
            'code_verifier' => 'required|string',
        ]);

        try {
            // Exchange authorization code for access token
            $clientId = config('services.truecaller.client_id');

            $tokenResponse = Http::asForm()->post('https://oauth-account-noneu.truecaller.com/v1/token', [
                'grant_type' => 'authorization_code',
                'client_id' => $clientId,
                'code' => $request->authorization_code,
                'code_verifier' => $request->code_verifier,
            ]);

            if (!$tokenResponse->successful()) {
                Log::error('Truecaller token exchange failed', [
                    'status' => $tokenResponse->status(),
                    'body' => $tokenResponse->json(),
                    'client_id' => $clientId,
                    'has_code' => !empty($request->authorization_code),
                    'has_verifier' => !empty($request->code_verifier),
                ]);
                return response()->json([
                    'success' => false,
                    'message' => 'Truecaller verification failed. Please try OTP.',
                    'use_otp' => true,
                    'debug_error' => $tokenResponse->json(),
                ], 400);
            }

            $tokenData = $tokenResponse->json();
            $accessToken = $tokenData['access_token'] ?? null;

            if (!$accessToken) {
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to get access token from Truecaller.',
                    'use_otp' => true,
                ], 400);
            }

            // Fetch user profile from Truecaller
            $profileResponse = Http::withToken($accessToken)
                ->get('https://oauth-account-noneu.truecaller.com/v1/userinfo');

            if (!$profileResponse->successful()) {
                Log::error('Truecaller profile fetch failed', [
                    'status' => $profileResponse->status(),
                    'body' => $profileResponse->body(),
                ]);
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to fetch profile from Truecaller.',
                    'use_otp' => true,
                ], 400);
            }

            $profile = $profileResponse->json();
            $phone = $profile['phone_number'] ?? null;

            // Remove country code if present (keep last 10 digits for India)
            if ($phone && strlen($phone) > 10) {
                $phone = substr($phone, -10);
            }

            if (!$phone) {
                return response()->json([
                    'success' => false,
                    'message' => 'Could not retrieve phone number from Truecaller.',
                    'use_otp' => true,
                ], 400);
            }

            // Check if user exists
            $user = User::where('phone', $phone)->first();

            if ($user) {
                // Existing user - login
                $token = $user->createToken('auth-token')->plainTextToken;
                $user->update(['status' => 'online']);

                return response()->json([
                    'success' => true,
                    'is_new_user' => false,
                    'phone' => $phone,
                    'token' => $token,
                    'user' => $this->formatUserResponse($user),
                ]);
            } else {
                // New user - return registration token
                return response()->json([
                    'success' => true,
                    'is_new_user' => true,
                    'phone' => $phone,
                    'registration_token' => encrypt($phone . '|' . now()->timestamp),
                ]);
            }

        } catch (\Exception $e) {
            Log::error('Truecaller verification error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Truecaller verification failed. Please try OTP.',
                'use_otp' => true,
            ], 500);
        }
    }


    /**
     * Complete registration (new user)
     */
    public function register(Request $request): JsonResponse
    {
        $request->validate([
            'registration_token' => 'required|string',
            'user_type' => 'required|in:male,female',
            'name' => 'nullable|string|max:100',
            'age' => 'nullable|integer|min:18|max:100',
            'bio' => 'nullable|string|max:500',
            'avatar' => 'nullable|string|max:255', // Avatar URL or path
            'voice_verification' => 'nullable|file|max:10240', // 10MB max, any audio format
            'languages' => 'nullable|string', // Comma separated languages
        ]);

        // Decrypt and validate registration token
        try {
            $decrypted = decrypt($request->registration_token);
            [$phone, $timestamp] = explode('|', $decrypted);

            // Token expires in 30 minutes
            if (now()->timestamp - (int) $timestamp > 1800) {
                return response()->json([
                    'success' => false,
                    'message' => 'Registration token expired. Please verify phone again.',
                ], 400);
            }
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid registration token.',
            ], 400);
        }

        // Check if user already exists
        if (User::where('phone', $phone)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'User already exists with this phone number.',
            ], 400);
        }

        // Handle avatar - now accepts URL string instead of file upload
        $avatarPath = $request->avatar; // Avatar URL or path string

        // Auto-generate name if not provided
        $name = $request->name ?? 'User_' . rand(1000, 9999);

        // Create user
        $userData = [
            'phone' => $phone,
            'user_type' => $request->user_type,
            'name' => $name,
            'age' => $request->age,
            'bio' => $request->bio,
            'avatar' => $avatarPath,
            'password' => Hash::make(str()->random(32)), // Random password for API-only auth
            'status' => 'online',
            'account_status' => $request->input('user_type') === 'female' ? 'pending' : 'active', // Females need admin approval
            'is_verified' => $request->input('user_type') === 'male', // Males auto-verified
            'last_seen' => now(),
            'voice_status' => $request->input('user_type') === 'female' ? 'pending' : 'none',
            'languages' => $request->input('languages') ? explode(',', $request->input('languages')) : null,
        ];

        if ($request->hasFile('voice_verification')) {
            $voicePath = $request->file('voice_verification')->store('voice_verifications', 'public');
            $userData['voice_verification_path'] = $voicePath;
        }

        $user = User::create($userData);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => $request->user_type === 'female'
                ? 'Registration successful. Your profile is pending admin approval.'
                : 'Registration successful',
            'user' => $this->formatUserResponse($user),
            'token' => $token,
        ], 201);
    }

    /**
     * Get current user profile
     */
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'user' => $this->formatUserResponse($user),
        ]);
    }

    /**
     * Update profile
     */
    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        $request->validate([
            'name' => 'sometimes|string|max:100',
            'age' => 'sometimes|integer|min:18|max:100',
            'bio' => 'sometimes|string|max:500',
            'location' => 'sometimes|string|max:100',
            'avatar' => 'sometimes|image|max:5120',
        ]);

        if ($request->has('name'))
            $user->name = $request->name;
        if ($request->has('age'))
            $user->age = $request->age;
        if ($request->has('bio'))
            $user->bio = $request->bio;
        if ($request->has('location'))
            $user->location = $request->location;

        if ($request->hasFile('avatar')) {
            $avatarPath = $request->file('avatar')->store('avatars', 'public');
            $user->avatar = $avatarPath;
        }

        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully',
            'user' => $this->formatUserResponse($user),
        ]);
    }

    /**
     * Logout
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->status = 'offline';
        $user->last_seen = now();
        $user->save();

        // Revoke current token
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully',
        ]);
    }

    /**
     * Update user online status (Female only)
     */
    public function updateOnlineStatus(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'is_online' => 'required|boolean',
        ]);

        $user->update([
            'status' => $request->is_online ? 'online' : 'offline',
        ]);

        return response()->json([
            'success' => true,
            'message' => $request->is_online ? 'You are now online' : 'You are now offline',
            'status' => $user->status,
        ]);
    }

    /**
     * Update FCM token for push notifications
     */
    public function updateFcmToken(Request $request): JsonResponse
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $user = $request->user();
        $user->fcm_token = $request->fcm_token;
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'FCM token updated',
        ]);
    }

    /**
     * Format user response based on user type
     */
    private function formatUserResponse(User $user): array
    {
        $base = [
            'id' => $user->id,
            'user_type' => $user->user_type,
            'phone' => substr($user->phone, 0, 2) . 'XXXXXX' . substr($user->phone, -2), // Masked
            'name' => $user->name,
            'age' => $user->age,
            'bio' => $user->bio,
            'avatar' => $this->formatAvatarUrl($user->avatar),
            'location' => $user->location,
            'status' => $user->status,
            'account_status' => $user->account_status,
            'is_verified' => $user->is_verified,
            'is_in_chat' => $user->isInChat(),
            'voice_status' => $user->voice_status,
            'voice_verification_url' => $user->voice_verification_path ? asset('storage/' . $user->voice_verification_path) : null,
        ];

        if ($user->isMale()) {
            $base['coin_balance'] = $user->coin_balance;
            $base['total_coins_purchased'] = $user->total_coins_purchased;
            $base['total_coins_spent'] = $user->total_coins_spent;
        }

        if ($user->isFemale()) {
            $base['earning_balance'] = $user->earning_balance;
            $base['total_earned'] = $user->total_earned;
            $base['total_withdrawn'] = $user->total_withdrawn;
            $base['rate_per_minute'] = $user->rate_per_minute;
            $base['has_bank_details'] = !empty($user->bank_account_number);
        }

        return $base;
    }

    /**
     * Format avatar URL - handles http URLs, local Flutter assets, and storage paths
     */
    private function formatAvatarUrl(?string $avatar): ?string
    {
        if (!$avatar) {
            return null;
        }

        // If it's already an HTTP URL, return as-is
        if (str_starts_with($avatar, 'http')) {
            return $avatar;
        }

        // If it's a local Flutter asset path (e.g., assets/images/avatars/avatar_1.png), return as-is
        if (str_starts_with($avatar, 'assets/')) {
            return $avatar;
        }

        // Otherwise, it's a storage path (uploaded file), prepend storage URL
        return asset('storage/' . $avatar);
    }
}

