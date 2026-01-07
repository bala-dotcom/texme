<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'amount',
        'coins',
        'gateway',
        'gateway_order_id',
        'gateway_payment_id',
        'status',
        'metadata',
        'chat_id',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'coins' => 'integer',
            'metadata' => 'array',
        ];
    }

    // ========== RELATIONSHIPS ==========

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function chat(): BelongsTo
    {
        return $this->belongsTo(Chat::class);
    }

    // ========== HELPER METHODS ==========

    public function isCoinPurchase(): bool
    {
        return $this->type === 'coin_purchase';
    }

    public function isCoinDeduction(): bool
    {
        return $this->type === 'coin_deduction';
    }

    public function isEarning(): bool
    {
        return $this->type === 'earning';
    }

    public function isWithdrawal(): bool
    {
        return $this->type === 'withdrawal';
    }

    public function markAsSuccess(): void
    {
        $this->status = 'success';
        $this->save();
    }

    public function markAsFailed(): void
    {
        $this->status = 'failed';
        $this->save();
    }
}
