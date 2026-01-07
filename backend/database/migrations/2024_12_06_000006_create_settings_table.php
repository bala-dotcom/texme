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
        Schema::create('settings', function (Blueprint $table) {
            $table->id();
            $table->string('key', 50)->unique();
            $table->text('value');
            $table->string('description')->nullable();
            $table->timestamps();
        });
        
        // Insert default settings
        $this->seedDefaultSettings();
    }
    
    /**
     * Seed default settings
     */
    private function seedDefaultSettings(): void
    {
        $settings = [
            // Coin packages (JSON array)
            [
                'key' => 'coin_packages',
                'value' => json_encode([
                    ['coins' => 40, 'price' => 25, 'bonus' => 0, 'label' => 'Starter'],
                    ['coins' => 85, 'price' => 50, 'bonus' => 5, 'label' => 'Popular'],
                    ['coins' => 180, 'price' => 100, 'bonus' => 20, 'label' => 'Best Value'],
                    ['coins' => 400, 'price' => 200, 'bonus' => 50, 'label' => 'Premium'],
                ]),
                'description' => 'Available coin packages for purchase'
            ],
            // Coin rate per minute
            [
                'key' => 'coins_per_minute',
                'value' => '10',
                'description' => 'Coins deducted per minute of chat'
            ],
            // Female earning ratio (percentage of coin value)
            [
                'key' => 'female_earning_ratio',
                'value' => '0.36',
                'description' => 'Percentage of coin value that goes to female (0.36 = 36%)'
            ],
            // Minimum withdrawal
            [
                'key' => 'min_withdrawal',
                'value' => '500',
                'description' => 'Minimum withdrawal amount in INR'
            ],
            // Active payment gateway
            [
                'key' => 'active_payment_gateway',
                'value' => 'razorpay',
                'description' => 'Currently active payment gateway'
            ],
            // Available payment gateways (JSON)
            [
                'key' => 'payment_gateways',
                'value' => json_encode([
                    'razorpay' => ['enabled' => true, 'priority' => 1],
                    'payu' => ['enabled' => false, 'priority' => 2],
                    'cashfree' => ['enabled' => false, 'priority' => 3],
                ]),
                'description' => 'Payment gateway configuration'
            ],
        ];
        
        foreach ($settings as $setting) {
            \DB::table('settings')->insert([
                'key' => $setting['key'],
                'value' => $setting['value'],
                'description' => $setting['description'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('settings');
    }
};
