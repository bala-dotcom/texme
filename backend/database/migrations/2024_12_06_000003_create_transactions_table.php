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
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->enum('type', ['coin_purchase', 'coin_deduction', 'earning', 'withdrawal']);
            $table->decimal('amount', 10, 2)->default(0); // Money in INR
            $table->integer('coins')->nullable(); // For coin transactions
            $table->enum('gateway', ['razorpay', 'payu', 'cashfree'])->nullable();
            $table->string('gateway_order_id', 100)->nullable();
            $table->string('gateway_payment_id', 100)->nullable();
            $table->enum('status', ['pending', 'success', 'failed'])->default('pending');
            $table->json('metadata')->nullable(); // Gateway response data
            $table->foreignId('chat_id')->nullable()->constrained('chats')->onDelete('set null');
            $table->timestamps();
            
            // Indexes
            $table->index(['user_id', 'type']);
            $table->index(['user_id', 'created_at']);
            $table->index('gateway_order_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
