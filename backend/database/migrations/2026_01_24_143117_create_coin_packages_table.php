<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('coin_packages', function (Blueprint $blueprint) {
            $blueprint->id();
            $blueprint->string('label');
            $blueprint->integer('price');
            $blueprint->integer('coins');
            $blueprint->integer('bonus')->default(0);
            $blueprint->boolean('is_active')->default(true);
            $blueprint->integer('sort_order')->default(0);
            $blueprint->timestamps();
        });

        // Seed initial data
        DB::table('coin_packages')->insert([
            ['label' => 'Starter', 'price' => 25, 'coins' => 40, 'bonus' => 0, 'sort_order' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['label' => 'Popular', 'price' => 59, 'coins' => 100, 'bonus' => 0, 'sort_order' => 2, 'created_at' => now(), 'updated_at' => now()],
            ['label' => 'Best Value', 'price' => 99, 'coins' => 200, 'bonus' => 0, 'sort_order' => 3, 'created_at' => now(), 'updated_at' => now()],
            ['label' => 'Premium', 'price' => 199, 'coins' => 500, 'bonus' => 0, 'sort_order' => 4, 'created_at' => now(), 'updated_at' => now()],
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('coin_packages');
    }
};
