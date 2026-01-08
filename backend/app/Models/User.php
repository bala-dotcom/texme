<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Crypt;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'user_type',
        'phone',
        'email',
        'password',
        'name',
        'age',
        'bio',
        'avatar',
        'location',
        'coin_balance',
        'total_coins_purchased',
        'total_coins_spent',
        'earning_balance',
        'total_earned',
        'total_withdrawn',
        'rate_per_minute',
        'bank_account_name',
        'bank_account_number',
        'bank_ifsc',
        'bank_name',
        'upi_id',
        'status',
        'account_status',
        'is_verified',
        'last_seen',
        'active_chat_id',
    ];

    /**
     * The attributes that should be hidden for serialization.
     */
    protected $hidden = [
        'password',
        'remember_token',
        'bank_account_name',
        'bank_account_number',
        'bank_ifsc',
        'bank_name',
        'upi_id',
    ];

    /**
     * Get the attributes that should be cast.
     */
    protected function casts(): array
    {
        return [
            'password' => 'hashed',
            'is_verified' => 'boolean',
            'last_seen' => 'datetime',
            'coin_balance' => 'integer',
            'total_coins_purchased' => 'integer',
            'total_coins_spent' => 'integer',
            'earning_balance' => 'decimal:2',
            'total_earned' => 'decimal:2',
            'total_withdrawn' => 'decimal:2',
            'rate_per_minute' => 'decimal:2',
        ];
    }

    // ========== RELATIONSHIPS ==========

    /**
     * Chats where user is male participant
     */
    public function chatsAsMale(): HasMany
    {
        return $this->hasMany(Chat::class, 'male_user_id');
    }

    /**
     * Chats where user is female participant
     */
    public function chatsAsFemale(): HasMany
    {
        return $this->hasMany(Chat::class, 'female_user_id');
    }

    /**
     * All transactions for this user
     */
    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }

    /**
     * Withdrawals (for female users)
     */
    public function withdrawals(): HasMany
    {
        return $this->hasMany(Withdrawal::class);
    }

    /**
     * Reports made by this user
     */
    public function reportsMade(): HasMany
    {
        return $this->hasMany(Report::class, 'reported_by');
    }

    /**
     * Reports received by this user
     */
    public function reportsReceived(): HasMany
    {
        return $this->hasMany(Report::class, 'reported_user');
    }

    /**
     * Active chat
     */
    public function activeChat(): BelongsTo
    {
        return $this->belongsTo(Chat::class, 'active_chat_id');
    }

    // ========== HELPER METHODS ==========

    /**
     * Check if user is male
     */
    public function isMale(): bool
    {
        return $this->user_type === 'male';
    }

    /**
     * Check if user is female
     */
    public function isFemale(): bool
    {
        return $this->user_type === 'female';
    }

    /**
     * Check if user is online and available
     */
    public function isAvailable(): bool
    {
        return $this->status === 'online' && $this->account_status === 'active';
    }

    /**
     * Check if user is in active chat
     */
    public function isInChat(): bool
    {
        if ($this->status !== 'busy' || $this->active_chat_id === null) {
            return false;
        }

        // Verify the chat is actually active
        $chat = Chat::find($this->active_chat_id);
        if (!$chat || $chat->status !== 'active') {
            // The chat ended but user status wasn't updated - fix it now
            $this->status = 'online';
            $this->active_chat_id = null;
            $this->save();
            return false;
        }

        return true;
    }

    /**
     * Get potential earnings for female (based on male's coin balance)
     */
    public function getPotentialEarningsAttribute(): float
    {
        if ($this->isMale()) {
            $setting = Setting::where('key', 'female_earning_ratio')->first();
            $ratio = $setting ? (float) $setting->value : 0.36;

            // Calculate how many minutes of chat possible
            $coinsPerMin = Setting::where('key', 'coins_per_minute')->first();
            $coinsPerMinute = $coinsPerMin ? (int) $coinsPerMin->value : 10;

            $possibleMinutes = floor($this->coin_balance / $coinsPerMinute);

            // Calculate earning (coin_value * ratio)
            // Assuming 40 coins = ₹25, so 1 coin = ₹0.625
            $coinValue = 0.625;
            return round($this->coin_balance * $coinValue * $ratio, 2);
        }
        return 0;
    }

    /**
     * Deduct coins (for male users)
     */
    public function deductCoins(int $amount): bool
    {
        if ($this->coin_balance >= $amount) {
            $this->coin_balance -= $amount;
            $this->total_coins_spent += $amount;
            $this->save();
            return true;
        }
        return false;
    }

    /**
     * Add earnings (for female users)
     */
    public function addEarnings(float $amount): void
    {
        $this->earning_balance += $amount;
        $this->total_earned += $amount;
        $this->save();
    }

    /**
     * Set user status
     */
    public function setStatus(string $status): void
    {
        $this->status = $status;
        if ($status !== 'busy') {
            $this->active_chat_id = null;
        }
        $this->save();
    }

    /**
     * Get decrypted bank details
     */
    public function getDecryptedBankDetails(): array
    {
        return [
            'account_name' => $this->bank_account_name ? Crypt::decryptString($this->bank_account_name) : null,
            'account_number' => $this->bank_account_number ? Crypt::decryptString($this->bank_account_number) : null,
            'ifsc' => $this->bank_ifsc,
            'bank_name' => $this->bank_name,
            'upi_id' => $this->upi_id,
        ];
    }

    /**
     * Set encrypted bank details
     */
    public function setBankDetails(array $details): void
    {
        if (isset($details['account_name'])) {
            $this->bank_account_name = Crypt::encryptString($details['account_name']);
        }
        if (isset($details['account_number'])) {
            $this->bank_account_number = Crypt::encryptString($details['account_number']);
        }
        if (isset($details['ifsc'])) {
            $this->bank_ifsc = $details['ifsc'];
        }
        if (isset($details['bank_name'])) {
            $this->bank_name = $details['bank_name'];
        }
        if (isset($details['upi_id'])) {
            $this->upi_id = $details['upi_id'];
        }
        $this->save();
    }
}
