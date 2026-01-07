<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->enum('user_type', ['male', 'female']);
            $table->string('phone', 15)->unique();
            $table->string('email')->nullable();
            $table->string('password');
            $table->string('name', 100);
            $table->integer('age')->nullable();
            $table->text('bio')->nullable();
            $table->string('avatar', 500)->nullable();
            $table->string('location', 100)->nullable();
            
            // Male specific - Coin system
            $table->integer('coin_balance')->default(0);
            $table->integer('total_coins_purchased')->default(0);
            $table->integer('total_coins_spent')->default(0);
            
            // Female specific - Earnings system
            $table->decimal('earning_balance', 10, 2)->default(0);
            $table->decimal('total_earned', 10, 2)->default(0);
            $table->decimal('total_withdrawn', 10, 2)->default(0);
            $table->decimal('rate_per_minute', 5, 2)->default(3.00);
            
            // Bank Details (Female) - Encrypted
            $table->text('bank_account_name')->nullable();
            $table->text('bank_account_number')->nullable();
            $table->string('bank_ifsc', 15)->nullable();
            $table->string('bank_name', 100)->nullable();
            $table->string('upi_id', 50)->nullable();
            
            // Status and verification
            $table->enum('status', ['online', 'busy', 'offline'])->default('offline');
            $table->enum('account_status', ['active', 'suspended', 'pending'])->default('pending');
            $table->boolean('is_verified')->default(false);
            $table->timestamp('last_seen')->nullable();
            
            // Active chat tracking
            $table->unsignedBigInteger('active_chat_id')->nullable();
            
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('phone')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('sessions');
    }
};
