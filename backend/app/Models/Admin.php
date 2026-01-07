<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Laravel\Sanctum\HasApiTokens;

class Admin extends Authenticatable
{
    use HasFactory, HasApiTokens;

    protected $guard = 'admin';

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'is_active',
        'two_factor_secret',
        'last_login_at',
        'last_login_ip',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'two_factor_secret',
    ];

    protected function casts(): array
    {
        return [
            'password' => 'hashed',
            'is_active' => 'boolean',
            'last_login_at' => 'datetime',
        ];
    }

    // ========== RELATIONSHIPS ==========

    public function logs(): HasMany
    {
        return $this->hasMany(AdminLog::class);
    }

    // ========== HELPER METHODS ==========

    public function isSuperAdmin(): bool
    {
        return $this->role === 'super_admin';
    }

    public function isModerator(): bool
    {
        return $this->role === 'moderator';
    }

    public function isFinance(): bool
    {
        return $this->role === 'finance';
    }

    /**
     * Check if admin has permission for action
     */
    public function hasPermission(string $permission): bool
    {
        // Super admin has all permissions
        if ($this->isSuperAdmin()) {
            return true;
        }

        $permissions = [
            'moderator' => [
                'users.view',
                'users.suspend',
                'reports.view',
                'reports.manage',
                'chats.view',
            ],
            'finance' => [
                'transactions.view',
                'withdrawals.view',
                'withdrawals.manage',
                'users.view',
            ],
        ];

        $rolePermissions = $permissions[$this->role] ?? [];
        return in_array($permission, $rolePermissions);
    }

    /**
     * Log admin action
     */
    public function logAction(string $action, string $targetType = null, int $targetId = null, array $details = null): void
    {
        AdminLog::create([
            'admin_id' => $this->id,
            'action' => $action,
            'target_type' => $targetType,
            'target_id' => $targetId,
            'details' => $details,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
        ]);
    }

    /**
     * Update login info
     */
    public function recordLogin(): void
    {
        $this->last_login_at = now();
        $this->last_login_ip = request()->ip();
        $this->save();
    }
}
