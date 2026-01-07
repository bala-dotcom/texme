<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Withdrawal extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'amount',
        'bank_details',
        'status',
        'admin_notes',
        'processed_at',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'bank_details' => 'array',
            'processed_at' => 'datetime',
        ];
    }

    // ========== RELATIONSHIPS ==========

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    // ========== HELPER METHODS ==========

    public function isPending(): bool
    {
        return $this->status === 'pending';
    }

    public function isProcessing(): bool
    {
        return $this->status === 'processing';
    }

    public function isCompleted(): bool
    {
        return $this->status === 'completed';
    }

    public function isRejected(): bool
    {
        return $this->status === 'rejected';
    }

    public function approve(): void
    {
        $this->status = 'processing';
        $this->save();
    }

    public function complete(): void
    {
        $this->status = 'completed';
        $this->processed_at = now();
        $this->save();

        // Deduct from user's earning balance
        $this->user->earning_balance -= $this->amount;
        $this->user->total_withdrawn += $this->amount;
        $this->user->save();
    }

    public function reject(string $reason = null): void
    {
        $this->status = 'rejected';
        $this->admin_notes = $reason;
        $this->processed_at = now();
        $this->save();
    }
}
