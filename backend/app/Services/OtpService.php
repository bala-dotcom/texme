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
            $response = Http::withHeaders([
                'authkey' => $this->apiKey,
                'Content-Type' => 'application/json',
            ])->post('https://control.msg91.com/api/v5/otp', [
                'template_id' => config('services.otp.msg91_template_id'),
                'mobile' => $phone,
                'otp' => $otp,
            ]);

            if ($response->successful()) {
                return true;
            }

            Log::error('MSG91 OTP Error: ' . $response->body());
            return false;
        } catch (\Exception $e) {
            Log::error('MSG91 OTP Exception: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Send OTP via 2Factor
     */
    private function sendVia2Factor(string $phone, string $otp): bool
    {
        try {
            $response = Http::get("https://2factor.in/API/V1/{$this->apiKey}/SMS/{$phone}/{$otp}");

            if ($response->successful()) {
                $data = $response->json();
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
        // We handle verification in OtpVerification model
        // This is for providers that have their own verification API
        return true;
    }
}
