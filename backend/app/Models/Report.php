<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Report extends Model
{
    use HasFactory;

    protected $fillable = [
        'reported_by',
        'reported_user',
        'chat_id',
        'reason',
        'description',
        'status',
        'admin_notes',
        'reviewed_at',
    ];

    protected function casts(): array
    {
        return [
            'reviewed_at' => 'datetime',
        ];
    }

    // ========== RELATIONSHIPS ==========

    public function reporter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reported_by');
    }

    public function reportedUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reported_user');
    }

    public function chat(): BelongsTo
    {
        return $this->belongsTo(Chat::class);
    }

    // ========== HELPER METHODS ==========

    public function isPending(): bool
    {
        return $this->status === 'pending';
    }

    public function markAsReviewed(string $notes = null): void
    {
        $this->status = 'reviewed';
        $this->admin_notes = $notes;
        $this->reviewed_at = now();
        $this->save();
    }

    public function takeAction(string $notes = null): void
    {
        $this->status = 'action_taken';
        $this->admin_notes = $notes;
        $this->reviewed_at = now();
        $this->save();
    }

    public function dismiss(string $notes = null): void
    {
        $this->status = 'dismissed';
        $this->admin_notes = $notes;
        $this->reviewed_at = now();
        $this->save();
    }
}
