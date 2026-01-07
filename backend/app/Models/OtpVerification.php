<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OtpVerification extends Model
{
    use HasFactory;

    protected $fillable = [
        'phone',
        'otp',
        'expires_at',
        'is_verified',
        'attempts',
    ];

    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
            'is_verified' => 'boolean',
            'attempts' => 'integer',
        ];
    }

    // ========== HELPER METHODS ==========

    /**
     * Check if OTP is expired
     */
    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    /**
     * Check if too many attempts
     */
    public function hasTooManyAttempts(): bool
    {
        return $this->attempts >= 5;
    }

    /**
     * Increment attempts
     */
    public function incrementAttempts(): void
    {
        $this->attempts++;
        $this->save();
    }

    /**
     * Verify OTP
     */
    public function verify(string $otp): bool
    {
        if ($this->isExpired()) {
            return false;
        }

        if ($this->hasTooManyAttempts()) {
            return false;
        }

        if ($this->otp !== $otp) {
            $this->incrementAttempts();
            return false;
        }

        $this->is_verified = true;
        $this->save();
        return true;
    }

    /**
     * Generate new OTP for phone
     */
    public static function generateForPhone(string $phone): self
    {
        // Delete any existing unverified OTPs for this phone
        self::where('phone', $phone)->where('is_verified', false)->delete();

        // Generate 6-digit OTP
        $otp = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        return self::create([
            'phone' => $phone,
            'otp' => $otp,
            'expires_at' => now()->addMinutes(10),
            'is_verified' => false,
            'attempts' => 0,
        ]);
    }
}
