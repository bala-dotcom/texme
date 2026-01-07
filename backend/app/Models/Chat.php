<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Chat extends Model
{
    use HasFactory;

    protected $fillable = [
        'male_user_id',
        'female_user_id',
        'status',
        'started_at',
        'ended_at',
        'total_minutes',
        'coins_spent',
        'female_earnings',
    ];

    protected function casts(): array
    {
        return [
            'started_at' => 'datetime',
            'ended_at' => 'datetime',
            'total_minutes' => 'integer',
            'coins_spent' => 'integer',
            'female_earnings' => 'decimal:2',
        ];
    }

    // ========== RELATIONSHIPS ==========

    public function maleUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'male_user_id');
    }

    public function femaleUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'female_user_id');
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }

    // ========== HELPER METHODS ==========

    /**
     * Check if chat is active
     */
    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    /**
     * Check if chat is pending (waiting for accept)
     */
    public function isPending(): bool
    {
        return $this->status === 'pending';
    }

    /**
     * Start the chat (when female accepts)
     */
    public function start(): void
    {
        $this->status = 'active';
        $this->started_at = now();
        $this->save();

        // Update both users' status
        $this->maleUser->status = 'busy';
        $this->maleUser->active_chat_id = $this->id;
        $this->maleUser->save();

        $this->femaleUser->status = 'busy';
        $this->femaleUser->active_chat_id = $this->id;
        $this->femaleUser->save();
    }

    /**
     * End the chat
     */
    public function end(): void
    {
        $this->status = 'ended';
        $this->ended_at = now();
        
        // Calculate total minutes
        if ($this->started_at) {
            $this->total_minutes = $this->started_at->diffInMinutes($this->ended_at);
        }
        
        $this->save();

        // Update both users' status
        $this->maleUser->status = 'online';
        $this->maleUser->active_chat_id = null;
        $this->maleUser->save();

        $this->femaleUser->status = 'online';
        $this->femaleUser->active_chat_id = null;
        $this->femaleUser->save();
    }

    /**
     * Decline chat request
     */
    public function decline(): void
    {
        // Keep DB enum compatibility (pending|active|ended)
        $this->status = 'ended';
        $this->ended_at = now();
        $this->save();
    }

    /**
     * Add minute charges
     */
    public function addMinuteCharge(int $coins, float $earnings): void
    {
        $this->coins_spent += $coins;
        $this->female_earnings += $earnings;
        $this->total_minutes += 1;
        $this->save();
    }
}
