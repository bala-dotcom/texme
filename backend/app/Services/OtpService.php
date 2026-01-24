<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class OtpService
{
    private string $provider;
    private ?string $apiKey;
    private string $senderId;

    public function __construct()
    {
        $this->provider = config('services.otp.provider', 'msg91');
        $this->apiKey = config('services.otp.api_key', '');
        $this->senderId = config('services.otp.sender_id', 'TEXME');
    }

    /**
     * Send OTP to phone number
     */
    public function send(string $phone, string $otp): bool
    {
        // Add country code if not present
        if (!str_starts_with($phone, '91')) {
            $phone = '91' . $phone;
        }

        $message = "Your Texme verification code is: {$otp}. Valid for 10 minutes. Do not share with anyone.";

        switch ($this->provider) {
            case 'msg91':
                return $this->sendViaMSG91($phone, $message, $otp);
            case '2factor':
                return $this->sendVia2Factor($phone, $otp);
            case 'twilio':
                return $this->sendViaTwilio($phone, $message);
            default:
                // Development mode - log OTP
                Log::info("OTP for {$phone}: {$otp}");
                return true;
        }
    }

    /**
     * Send OTP via MSG91
     */
    private function sendViaMSG91(string $phone, string $message, string $otp): bool
    {
        try {
            Log::info("MSG91 sending OTP to {$phone}");

            // Use MSG91 direct Send OTP API
            $response = Http::withHeaders([
                'authkey' => $this->apiKey,
                'Content-Type' => 'application/json',
            ])->post('https://control.msg91.com/api/v5/otp', [
                        'template_id' => config('services.otp.msg91_template_id'),
                        'mobile' => $phone,
                        'otp' => $otp,
                    ]);

            Log::info('MSG91 Response: ' . $response->body());

            if ($response->successful()) {
                $data = $response->json();
                if (isset($data['type']) && $data['type'] === 'success') {
                    Log::info("MSG91 OTP sent successfully");
                    return true;
                }
            }

            Log::error('MSG91 OTP Error: ' . $response->body());
            return false;
        } catch (\Exception $e) {
            Log::error('MSG91 OTP Exception: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Send OTP via 2Factor (Strictly SMS Only)
     */
    private function sendVia2Factor(string $phone, string $otp): bool
    {
        try {
            // Using Transactional SMS endpoint for guaranteed SMS-only delivery
            $senderId = "TEXMEO";
            $message = "Your Texme verification code is: {$otp}. Valid for 10 minutes. Do not share with anyone.";

            Log::info("2Factor: Sending SMS-only OTP to {$phone}");

            // Standard SMS OTP URL with Sender ID
            $url = "https://2factor.in/API/V1/{$this->apiKey}/SMS/{$phone}/{$otp}/{$senderId}";

            $response = Http::timeout(10)->get($url);

            if ($response->successful()) {
                $data = $response->json();
                Log::info('2Factor Response: ' . $response->body());
                return isset($data['Status']) && $data['Status'] === 'Success';
            }

            Log::error('2Factor OTP Error: ' . $response->body());
            return false;
        } catch (\Exception $e) {
            Log::error('2Factor OTP Exception: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Send OTP via Twilio
     */
    private function sendViaTwilio(string $phone, string $message): bool
    {
        try {
            $sid = config('services.otp.twilio_sid');
            $token = config('services.otp.twilio_token');
            $from = config('services.otp.twilio_from');

            $response = Http::withBasicAuth($sid, $token)
                ->asForm()
                ->post("https://api.twilio.com/2010-04-01/Accounts/{$sid}/Messages.json", [
                    'From' => $from,
                    'To' => '+' . $phone,
                    'Body' => $message,
                ]);

            if ($response->successful()) {
                return true;
            }

            Log::error('Twilio OTP Error: ' . $response->body());
            return false;
        } catch (\Exception $e) {
            Log::error('Twilio OTP Exception: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Verify OTP (for providers that handle verification)
     */
    public function verify(string $phone, string $otp): bool
    {
        // Add country code if not present
        if (!str_starts_with($phone, '91')) {
            $phone = '91' . $phone;
        }

        if ($this->provider === 'msg91') {
            return $this->verifyMsg91Otp($phone, $otp);
        }

        // For 2factor and other providers, return false to force local OTP verification
        // (These providers don't have a verification API - OTP is stored locally)
        return false;
    }

    /**
     * Verify manual OTP via MSG91 API
     */
    private function verifyMsg91Otp(string $phone, string $otp): bool
    {
        try {
            $response = Http::get("https://control.msg91.com/api/v5/otp/verify", [
                'authkey' => $this->apiKey,
                'mobile' => $phone,
                'otp' => $otp,
            ]);

            if ($response->successful()) {
                $data = $response->json();
                return isset($data['type']) && $data['type'] === 'success';
            }

            return false;
        } catch (\Exception $e) {
            Log::error('MSG91 OTP Verify Exception: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Verify MSG91 Access Token
     */
    public function verifyMsg91Token(string $accessToken): ?string
    {
        try {
            $response = Http::withHeaders([
                'Content-Type' => 'application/json',
            ])->post('https://control.msg91.com/api/v5/widget/verifyAccessToken', [
                        'authkey' => $this->apiKey,
                        'access-token' => $accessToken,
                    ]);

            if ($response->successful()) {
                $data = $response->json();
                // MSG91 returns mobile number in response on success
                return $data['mobile'] ?? null;
            }

            Log::error('MSG91 Token Verify Error: ' . $response->body());
            return null;
        } catch (\Exception $e) {
            Log::error('MSG91 Token Verify Exception: ' . $e->getMessage());
            return null;
        }
    }
}
