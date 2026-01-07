<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Message extends Model
{
    use HasFactory;

    protected $fillable = [
        'chat_id',
        'sender_id',
        'receiver_id',
        'content',
        'type',
        'voice_url',
        'voice_duration',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'voice_duration' => 'integer',
        ];
    }

    // ========== RELATIONSHIPS ==========

    public function chat(): BelongsTo
    {
        return $this->belongsTo(Chat::class);
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function receiver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'receiver_id');
    }

    // ========== HELPER METHODS ==========

    public function isVoice(): bool
    {
        return $this->type === 'voice';
    }

    public function isText(): bool
    {
        return $this->type === 'text';
    }

    public function markAsDelivered(): void
    {
        $this->status = 'delivered';
        $this->save();
    }

    public function markAsRead(): void
    {
        $this->status = 'read';
        $this->save();
    }
}
