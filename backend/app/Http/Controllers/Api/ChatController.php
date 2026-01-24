<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Chat;
use App\Models\Message;
use App\Models\Report;
use App\Models\Setting;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

class ChatController extends Controller
{
    /**
     * Send chat request (male to female)
     */
    public function sendRequest(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isMale()) {
            return response()->json([
                'success' => false,
                'message' => 'Only male users can initiate chat',
            ], 403);
        }

        if ($user->isInChat()) {
            return response()->json([
                'success' => false,
                'message' => 'You are already in a chat',
            ], 400);
        }

        $request->validate([
            'female_id' => 'required|exists:users,id',
        ]);

        $female = User::find($request->female_id);

        if (!$female->isFemale()) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid user',
            ], 400);
        }

        if ($female->status !== 'online') {
            return response()->json([
                'success' => false,
                'message' => 'User is not available',
            ], 400);
        }

        $coinsPerMinute = Setting::getCoinsPerMinute();
        if ($user->coin_balance < $coinsPerMinute) {
            return response()->json([
                'success' => false,
                'message' => 'Not enough coins',
                'required_coins' => $coinsPerMinute,
                'your_balance' => $user->coin_balance,
            ], 400);
        }

        // Create pending chat
        $chat = Chat::create([
            'male_user_id' => $user->id,
            'female_user_id' => $female->id,
            'status' => 'pending',
        ]);

        // Calculate potential earnings for female
        $earningPerMin = Setting::getFemaleEarningPerMinute();
        $possibleMinutes = floor($user->coin_balance / $coinsPerMinute);
        $potentialEarning = round($possibleMinutes * $earningPerMin, 2);

        // Send push notification to female if she has FCM token
        if ($female->fcm_token) {
            $fcmService = new \App\Services\FcmService();
            $fcmService->sendIncomingCallNotification(
                $female->fcm_token,
                $chat->id,
                $user->name,
                $user->avatar ? asset('storage/' . $user->avatar) : null
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'Chat request sent',
            'chat_id' => $chat->id,
        ]);
    }

    /**
     * Accept chat request (female)
     */
    public function accept(Request $request, int $chatId): JsonResponse
    {
        $user = $request->user();

        if (!$user->isFemale()) {
            return response()->json([
                'success' => false,
                'message' => 'Only female users can accept requests',
            ], 403);
        }

        if ($user->isInChat()) {
            return response()->json([
                'success' => false,
                'message' => 'You are already in a chat',
            ], 400);
        }

        $chat = Chat::where('id', $chatId)
            ->where('female_user_id', $user->id)
            ->where('status', 'pending')
            ->first();

        if (!$chat) {
            return response()->json([
                'success' => false,
                'message' => 'Chat request not found or already processed',
            ], 404);
        }

        // Check if male still has coins
        $male = $chat->maleUser;
        $coinsPerMinute = Setting::getCoinsPerMinute();

        if ($male->coin_balance < $coinsPerMinute) {
            $chat->decline();
            return response()->json([
                'success' => false,
                'message' => 'User no longer has enough coins',
            ], 400);
        }

        DB::transaction(function () use ($chat) {
            $chat->start();
        });

        // Broadcast event (TODO: implement with Pusher)
        // event(new ChatAcceptedEvent($chat));

        return response()->json([
            'success' => true,
            'message' => 'Chat started',
            'chat_id' => $chat->id,
        ]);
    }

    /**
     * Decline chat request (female)
     */
    public function decline(Request $request, int $chatId): JsonResponse
    {
        $user = $request->user();

        if (!$user->isFemale()) {
            return response()->json([
                'success' => false,
                'message' => 'Only female users can decline requests',
            ], 403);
        }

        $chat = Chat::where('id', $chatId)
            ->where('female_user_id', $user->id)
            ->where('status', 'pending')
            ->first();

        if (!$chat) {
            return response()->json([
                'success' => false,
                'message' => 'Chat request not found',
            ], 404);
        }

        $chat->decline();

        // Broadcast event (TODO: implement with Pusher)
        // event(new ChatDeclinedEvent($chat));

        return response()->json([
            'success' => true,
            'message' => 'Chat request declined',
        ]);
    }

    /**
     * Get chat status (for polling)
     */
    public function getStatus(Request $request, int $chatId): JsonResponse
    {
        $user = $request->user();

        $chat = Chat::where('id', $chatId)
            ->where(function ($q) use ($user) {
                $q->where('male_user_id', $user->id)
                    ->orWhere('female_user_id', $user->id);
            })
            ->first();

        if (!$chat) {
            return response()->json([
                'success' => false,
                'message' => 'Chat not found',
            ], 404);
        }

        // Check if partner is typing or recording
        $partnerId = $user->id === $chat->male_user_id ? $chat->female_user_id : $chat->male_user_id;
        $isPartnerTyping = Cache::has("chat_{$chatId}_user_{$partnerId}_typing");
        $isPartnerRecording = Cache::has("chat_{$chatId}_user_{$partnerId}_recording");

        // Calculate remaining seconds based on male user's balance
        $maleId = $chat->male_user_id;
        $male = User::find($maleId);
        $coinsPerMinute = Setting::getCoinsPerMinute();
        $remainingSeconds = $male ? floor(($male->coin_balance / $coinsPerMinute) * 60) : 0;

        return response()->json([
            'success' => true,
            'status' => $chat->status,
            'chat_id' => $chat->id,
            'is_typing' => $isPartnerTyping,
            'is_recording' => $isPartnerRecording,
            'remaining_seconds' => (int) $remainingSeconds,
        ]);
    }

    /**
     * Set user typing status
     */
    public function setTyping(Request $request, int $chatId): JsonResponse
    {
        $user = $request->user();

        // Use cache to store typing status for 10 seconds
        Cache::put("chat_{$chatId}_user_{$user->id}_typing", true, now()->addSeconds(10));

        return response()->json([
            'success' => true,
        ]);
    }

    /**
     * Set user recording status
     */
    public function setRecording(Request $request, int $chatId): JsonResponse
    {
        $user = $request->user();

        // Use cache to store recording status for 10 seconds
        Cache::put("chat_{$chatId}_user_{$user->id}_recording", true, now()->addSeconds(10));

        return response()->json([
            'success' => true,
        ]);
    }

    /**
     * Cancel chat request (male user)
     */
    public function cancel(Request $request, int $chatId): JsonResponse
    {
        $user = $request->user();

        if (!$user->isMale()) {
            return response()->json([
                'success' => false,
                'message' => 'Only male users can cancel requests',
            ], 403);
        }

        $chat = Chat::where('id', $chatId)
            ->where('male_user_id', $user->id)
            ->where('status', 'pending')
            ->first();

        if (!$chat) {
            return response()->json([
                'success' => false,
                'message' => 'Chat request not found',
            ], 404);
        }

        // Keep DB enum compatibility (pending|active|ended)
        $chat->update([
            'status' => 'ended',
            'ended_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Chat request cancelled',
        ]);
    }

    /**
     * Send text message
     */
    public function sendMessage(Request $request, int $chatId): JsonResponse
    {
        $user = $request->user();

        $chat = $this->getActiveChat($user, $chatId);
        if (!$chat) {
            return response()->json([
                'success' => false,
                'message' => 'Chat not found or not active',
            ], 404);
        }

        $request->validate([
            'content' => 'required|string|max:1000',
        ]);

        $receiverId = $user->id === $chat->male_user_id
            ? $chat->female_user_id
            : $chat->male_user_id;

        $message = Message::create([
            'chat_id' => $chat->id,
            'sender_id' => $user->id,
            'receiver_id' => $receiverId,
            'content' => $request->input('content'),
            'type' => 'text',
        ]);

        // Broadcast event (TODO: implement with Pusher)
        // event(new NewMessageEvent($message));

        return response()->json([
            'success' => true,
            'message' => $this->formatMessage($message),
        ]);
    }

    /**
     * Send voice message
     */
    public function sendVoiceMessage(Request $request, int $chatId): JsonResponse
    {
        $user = $request->user();

        $chat = $this->getActiveChat($user, $chatId);
        if (!$chat) {
            return response()->json([
                'success' => false,
                'message' => 'Chat not found or not active',
            ], 404);
        }

        $request->validate([
            // Accept any file - mobile AAC recordings have inconsistent MIME types
            // We trust the mobile app to send valid audio files
            'voice' => 'required|file|max:10240', // 10MB max
            'duration' => 'required|integer|min:1|max:300', // Max 5 minutes
        ]);

        // Store with proper extension based on original filename or default to m4a
        $file = $request->file('voice');
        $extension = $file->getClientOriginalExtension() ?: 'm4a';
        $voicePath = $file->storeAs('voice_messages', uniqid('voice_') . '.' . $extension, 'public');

        $receiverId = $user->id === $chat->male_user_id
            ? $chat->female_user_id
            : $chat->male_user_id;

        $message = Message::create([
            'chat_id' => $chat->id,
            'sender_id' => $user->id,
            'receiver_id' => $receiverId,
            'type' => 'voice',
            'voice_url' => $voicePath,
            'voice_duration' => $request->duration,
        ]);

        // Broadcast event (TODO: implement with Pusher)
        // event(new NewMessageEvent($message));

        return response()->json([
            'success' => true,
            'message' => $this->formatMessage($message),
        ]);
    }

    /**
     * End chat
     */
    public function endChat(Request $request, int $chatId): JsonResponse
    {
        $user = $request->user();

        $chat = $this->getActiveChat($user, $chatId);
        if (!$chat) {
            return response()->json([
                'success' => false,
                'message' => 'Chat not found or not active',
            ], 404);
        }

        DB::transaction(function () use ($chat) {
            $chat->end();
        });

        // Broadcast event (TODO: implement with Pusher)
        // event(new ChatEndedEvent($chat));

        return response()->json([
            'success' => true,
            'message' => 'Chat ended',
            'summary' => [
                'total_minutes' => $chat->total_minutes,
                'coins_spent' => $chat->coins_spent,
                'female_earnings' => $chat->female_earnings,
            ],
        ]);
    }

    /**
     * Charge minute for active chat (called by frontend every minute)
     */
    public function chargeMinute(Request $request, int $chatId): JsonResponse
    {
        $user = $request->user();

        $chat = $this->getActiveChat($user, $chatId);
        if (!$chat) {
            return response()->json([
                'success' => false,
                'message' => 'Chat not found or not active',
            ], 404);
        }

        $coinsPerMinute = Setting::getCoinsPerMinute();
        $earnings = Setting::getFemaleEarningPerMinute(); // Fixed earning per minute

        $male = $chat->maleUser;

        // Check if male has enough coins
        if ($male->coin_balance < $coinsPerMinute) {
            // End chat - no more coins
            DB::transaction(function () use ($chat) {
                $chat->end();
            });

            return response()->json([
                'success' => false,
                'message' => 'Insufficient coins - chat ended',
                'chat_ended' => true,
            ], 400);
        }

        // earnings is already defined above as fixed per minute

        DB::transaction(function () use ($chat, $male, $coinsPerMinute, $earnings) {
            $female = $chat->femaleUser;

            // Deduct coins from male
            $male->coin_balance -= $coinsPerMinute;
            $male->total_coins_spent += $coinsPerMinute;
            $male->save();

            // Add earnings to female wallet fields (earning_balance / total_earned)
            $female->earning_balance += $earnings;
            $female->total_earned += $earnings;
            $female->save();

            // Update chat stats
            $chat->addMinuteCharge($coinsPerMinute, $earnings);

            // Create transaction records (match DB enum + columns)
            Transaction::create([
                'user_id' => $male->id,
                'type' => 'coin_deduction',
                'amount' => 0,
                'coins' => $coinsPerMinute,
                'status' => 'success',
                'chat_id' => $chat->id,
                'metadata' => [
                    'reason' => 'chat_minute',
                    'direction' => 'debit',
                    'partner_user_id' => $female->id,
                ],
            ]);

            Transaction::create([
                'user_id' => $female->id,
                'type' => 'earning',
                'amount' => $earnings,
                'status' => 'success',
                'chat_id' => $chat->id,
                'metadata' => [
                    'reason' => 'chat_minute',
                    'direction' => 'credit',
                    'partner_user_id' => $male->id,
                ],
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Minute charged',
            'coins_spent' => $coinsPerMinute,
            'female_earnings' => $earnings,
            'male_balance' => $male->coin_balance,
            'total_minutes' => $chat->total_minutes,
            'total_coins_spent' => $chat->coins_spent,
        ]);
    }

    /**
     * Get chat history
     */
    public function history(Request $request): JsonResponse
    {
        $user = $request->user();

        // Only show chats that actually started (exclude declined/cancelled pending requests)
        $query = Chat::where('status', 'ended')->whereNotNull('started_at');

        if ($user->isMale()) {
            $query->where('male_user_id', $user->id);
        } else {
            $query->where('female_user_id', $user->id);
        }

        $chats = $query->orderBy('ended_at', 'desc')
            ->with(['maleUser', 'femaleUser'])
            ->paginate(20);

        return response()->json([
            'success' => true,
            'chats' => $chats->map(fn($c) => $this->formatChatHistory($c, $user)),
            'pagination' => [
                'current_page' => $chats->currentPage(),
                'last_page' => $chats->lastPage(),
                'total' => $chats->total(),
            ],
        ]);
    }

    /**
     * Get messages for a chat
     */
    public function messages(Request $request, int $chatId): JsonResponse
    {
        $user = $request->user();

        $chat = Chat::where('id', $chatId)
            ->where(function ($q) use ($user) {
                $q->where('male_user_id', $user->id)
                    ->orWhere('female_user_id', $user->id);
            })
            ->first();

        if (!$chat) {
            return response()->json([
                'success' => false,
                'message' => 'Chat not found',
            ], 404);
        }

        $messages = Message::where('chat_id', $chatId)
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'messages' => $messages->map(fn($m) => $this->formatMessage($m)),
        ]);
    }

    /**
     * Get active chat
     */
    public function activeChat(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->active_chat_id) {
            return response()->json([
                'success' => true,
                'has_active_chat' => false,
            ]);
        }

        $chat = Chat::with(['maleUser:id,name,coin_balance', 'femaleUser:id,name,avatar'])
            ->find($user->active_chat_id);

        return response()->json([
            'success' => true,
            'has_active_chat' => true,
            'chat' => [
                'id' => $chat->id,
                'started_at' => $chat->started_at,
                'total_minutes' => $chat->total_minutes,
                'coins_spent' => $chat->coins_spent,
                'female_earnings' => $chat->female_earnings,
                'partner' => $user->isMale()
                    ? ['id' => $chat->femaleUser->id, 'name' => $chat->femaleUser->name, 'avatar' => $chat->femaleUser->avatar ? asset('storage/' . $chat->femaleUser->avatar) : null]
                    : ['id' => $chat->maleUser->id, 'name' => $chat->maleUser->name],
            ],
        ]);
    }

    /**
     * Get pending requests (for females)
     */
    public function pendingRequests(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isFemale()) {
            return response()->json([
                'success' => false,
                'message' => 'Only female users can view pending requests',
            ], 403);
        }

        // Auto-decline old pending requests (older than 120 seconds) - they are stale
        Chat::where('female_user_id', $user->id)
            ->where('status', 'pending')
            ->where('created_at', '<', now()->subSeconds(120))
            ->update([
                'status' => 'ended',
                'ended_at' => now(),
            ]);

        // Only return pending requests from the last 120 seconds
        $pendingChats = Chat::where('female_user_id', $user->id)
            ->where('status', 'pending')
            ->where('created_at', '>=', now()->subSeconds(120))
            ->with(['maleUser:id,name,avatar,coin_balance'])
            ->orderBy('created_at', 'desc')
            ->get();

        $coinsPerMinute = Setting::getCoinsPerMinute();
        $earningPerMin = Setting::getFemaleEarningPerMinute();

        return response()->json([
            'success' => true,
            'requests' => $pendingChats->map(function ($chat) use ($earningPerMin, $coinsPerMinute) {
                $possibleMinutes = floor($chat->maleUser->coin_balance / $coinsPerMinute);
                $potentialEarning = round($possibleMinutes * $earningPerMin, 2);
                return [
                    'chat_id' => $chat->id,
                    'male_id' => $chat->maleUser->id,
                    'male_name' => $chat->maleUser->name,
                    'male_avatar' => $chat->maleUser->avatar,
                    'potential_earning' => $potentialEarning,
                    'potential_earning_formatted' => '₹' . number_format($potentialEarning, 0),
                    'requested_at' => $chat->created_at,
                ];
            }),
        ]);
    }

    /**
     * Report a message
     */
    public function reportMessage(Request $request): JsonResponse
    {
        $request->validate([
            'message_id' => 'required|exists:messages,id',
            'reason' => 'required|string|max:100',
            'description' => 'nullable|string|max:500',
        ]);

        $message = Message::find($request->message_id);

        Report::create([
            'reported_by' => $request->user()->id,
            'reported_user' => $message->sender_id,
            'chat_id' => $message->chat_id,
            'reason' => $request->reason,
            'description' => $request->description,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Message reported. We will review it shortly.',
        ]);
    }

    // ========== HELPER METHODS ==========

    private function getActiveChat(User $user, int $chatId): ?Chat
    {
        return Chat::where('id', $chatId)
            ->where('status', 'active')
            ->where(function ($q) use ($user) {
                $q->where('male_user_id', $user->id)
                    ->orWhere('female_user_id', $user->id);
            })
            ->first();
    }

    private function formatMessage(Message $message): array
    {
        return [
            'id' => $message->id,
            'sender_id' => $message->sender_id,
            'type' => $message->type,
            'content' => $message->content,
            'voice_url' => $message->voice_url ? asset('storage/' . $message->voice_url) : null,
            'voice_duration' => $message->voice_duration,
            'status' => $message->status,
            'created_at' => $message->created_at,
        ];
    }

    private function formatChatHistory(Chat $chat, User $user): array
    {
        $partner = $user->isMale() ? $chat->femaleUser : $chat->maleUser;

        return [
            'chat_id' => $chat->id,
            'partner_id' => $partner->id,
            'partner_name' => $partner->name,
            'partner_avatar' => $partner->avatar ? asset('storage/' . $partner->avatar) : null,
            'partner_status' => $partner->status,
            'is_online' => ($partner->status === 'online' || $partner->status === 'busy'),
            'total_minutes' => $chat->total_minutes,
            'coins_spent' => $chat->coins_spent,
            'female_earnings' => $chat->female_earnings,
            'status' => $chat->status,
            'ended_at' => $chat->ended_at?->toIso8601String(),
        ];
    }
}
