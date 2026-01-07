<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Firebase\Messaging\AndroidConfig;
use Illuminate\Support\Facades\Log;

/**
 * Firebase Cloud Messaging Service using Admin SDK
 * Sends push notifications to Android/iOS devices
 */
class FcmService
{
    protected $messaging;
    protected bool $initialized = false;

    public function __construct()
    {
        $credentialsPath = base_path('firebase-credentials.json');
        
        if (file_exists($credentialsPath)) {
            try {
                $factory = (new Factory)->withServiceAccount($credentialsPath);
                $this->messaging = $factory->createMessaging();
                $this->initialized = true;
                Log::info('Firebase Messaging initialized');
            } catch (\Exception $e) {
                Log::error('Firebase initialization failed: ' . $e->getMessage());
            }
        } else {
            Log::warning('Firebase credentials file not found at: ' . $credentialsPath);
        }
    }

    /**
     * Send push notification to a device
     *
     * @param string $fcmToken Device FCM token
     * @param array $data Notification data
     * @param string|null $title Notification title
     * @param string|null $body Notification body
     * @return bool
     */
    public function sendToDevice(string $fcmToken, array $data = [], ?string $title = null, ?string $body = null): bool
    {
        if (!$this->initialized) {
            Log::warning('FCM not initialized, cannot send notification');
            return false;
        }

        try {
            $message = CloudMessage::withTarget('token', $fcmToken)
                ->withData($data);

            // Add notification for when app is in background
            if ($title || $body) {
                $notification = Notification::create($title, $body);
                $message = $message->withNotification($notification);
            }

            // Android-specific configuration for high priority
            $androidConfig = AndroidConfig::fromArray([
                'priority' => 'high',
                'notification' => [
                    'channel_id' => 'incoming_calls',
                    'sound' => 'default',
                    'default_sound' => true,
                    'default_vibrate_timings' => true,
                ],
            ]);
            $message = $message->withAndroidConfig($androidConfig);

            $this->messaging->send($message);
            
            Log::info('FCM notification sent successfully', ['token' => substr($fcmToken, 0, 20) . '...']);
            return true;

        } catch (\Kreait\Firebase\Exception\Messaging\NotFound $e) {
            Log::warning('FCM token not found (device unregistered)', ['token' => substr($fcmToken, 0, 20) . '...']);
            return false;
        } catch (\Exception $e) {
            Log::error('FCM send failed: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Send incoming call notification (DATA-ONLY for CallKit)
     * Does NOT include notification payload - CallKit handles the UI
     *
     * @param string $fcmToken
     * @param int $chatId
     * @param string $callerName
     * @param string|null $callerAvatar
     * @return bool
     */
    public function sendIncomingCallNotification(string $fcmToken, int $chatId, string $callerName, ?string $callerAvatar = null): bool
    {
        if (!$this->initialized) {
            Log::warning('FCM not initialized, cannot send incoming call notification');
            return false;
        }

        try {
            // DATA-ONLY message - no notification payload
            // This allows CallKit to handle the incoming call UI
            $data = [
                'type' => 'incoming_call',
                'chat_id' => (string) $chatId,
                'caller_name' => $callerName,
                'caller_avatar' => $callerAvatar ?? '',
            ];

            $message = CloudMessage::withTarget('token', $fcmToken)
                ->withData($data);

            // High priority to wake up the device
            $androidConfig = AndroidConfig::fromArray([
                'priority' => 'high',
            ]);
            $message = $message->withAndroidConfig($androidConfig);

            $this->messaging->send($message);
            
            Log::info('FCM incoming call notification sent', [
                'token' => substr($fcmToken, 0, 20) . '...',
                'chatId' => $chatId,
                'callerName' => $callerName
            ]);
            return true;

        } catch (\Kreait\Firebase\Exception\Messaging\NotFound $e) {
            Log::warning('FCM token not found for incoming call', ['token' => substr($fcmToken, 0, 20) . '...']);
            return false;
        } catch (\Exception $e) {
            Log::error('FCM incoming call send failed: ' . $e->getMessage());
            return false;
        }
    }
}

