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
        Schema::create('chats', function (Blueprint $table) {
            $table->id();
            $table->foreignId('male_user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('female_user_id')->constrained('users')->onDelete('cascade');
            $table->enum('status', ['pending', 'active', 'ended'])->default('pending');
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->integer('total_minutes')->default(0);
            $table->integer('coins_spent')->default(0);
            $table->decimal('female_earnings', 10, 2)->default(0);
            $table->timestamps();
            
            // Index for quick lookups
            $table->index(['male_user_id', 'status']);
            $table->index(['female_user_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('chats');
    }
};
