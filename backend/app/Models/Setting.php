<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Setting extends Model
{
    use HasFactory;

    protected $fillable = [
        'key',
        'value',
        'description',
    ];

    // ========== STATIC HELPER METHODS ==========

    /**
     * Get a setting value by key
     */
    public static function getValue(string $key, mixed $default = null): mixed
    {
        $setting = self::where('key', $key)->first();
        return $setting ? $setting->value : $default;
    }

    /**
     * Get a JSON setting value
     */
    public static function getJson(string $key, array $default = []): array
    {
        $value = self::getValue($key);
        return $value ? json_decode($value, true) : $default;
    }

    /**
     * Set a setting value
     */
    public static function setValue(string $key, mixed $value, ?string $description = null): void
    {
        self::updateOrCreate(
            ['key' => $key],
            [
                'value' => is_array($value) ? json_encode($value) : $value,
                'description' => $description,
            ]
        );
    }

    // ========== SPECIFIC GETTERS ==========

    /**
     * Get coin packages
     */
    public static function getCoinPackages(): array
    {
        return self::getJson('coin_packages', []);
    }

    /**
     * Get coins per minute
     */
    public static function getCoinsPerMinute(): int
    {
        return (int) self::getValue('coins_per_minute', 10);
    }

    /**
     * Get female earning per minute (₹)
     */
    public static function getFemaleEarningPerMinute(): float
    {
        return (float) self::getValue('female_earning_per_minute', 3.0);
    }

    /**
     * Get minimum withdrawal amount
     */
    public static function getMinWithdrawal(): int
    {
        return (int) self::getValue('minimum_withdrawal', 500);
    }

    /**
     * Get active payment gateway
     */
    public static function getActivePaymentGateway(): string
    {
        return self::getValue('active_payment_gateway', 'razorpay');
    }

    /**
     * Get all payment gateways configuration
     */
    public static function getPaymentGateways(): array
    {
        return self::getJson('payment_gateways', []);
    }
}
