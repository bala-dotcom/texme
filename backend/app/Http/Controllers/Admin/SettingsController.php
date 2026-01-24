<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use App\Models\AdminLog;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class SettingsController extends Controller
{
    /**
     * Get all settings
     */
    public function index(): JsonResponse
    {
        $settings = Setting::all()->mapWithKeys(function ($setting) {
            return [$setting->key => $setting->value];
        });

        return response()->json([
            'success' => true,
            'settings' => $settings,
        ]);
    }

    /**
     * Update a setting
     */
    public function update(Request $request): JsonResponse
    {
        $request->validate([
            'key' => 'required|string',
            'value' => 'required',
        ]);

        $setting = Setting::where('key', $request->key)->first();

        if (!$setting) {
            // Create new setting
            $setting = Setting::create([
                'key' => $request->key,
                'value' => $request->value,
            ]);
        } else {
            $setting->value = $request->value;
            $setting->save();
        }

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'setting_update',
            'description' => "Updated setting: {$request->key}",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Setting updated',
            'setting' => [
                'key' => $setting->key,
                'value' => $setting->value,
            ],
        ]);
    }

    /**
     * Update coin packages
     */
    public function updateCoinPackages(Request $request): JsonResponse
    {
        $request->validate([
            'packages' => 'required|array',
            'packages.*.coins' => 'required|integer|min:1',
            'packages.*.price' => 'required|integer|min:1',
            'packages.*.bonus' => 'nullable|integer|min:0',
            'packages.*.label' => 'nullable|string',
        ]);

        Setting::setValue('coin_packages', $request->packages);

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'coin_packages_update',
            'description' => 'Updated coin packages',
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Coin packages updated',
            'packages' => $request->packages,
        ]);
    }

    /**
     * Update rates
     */
    public function updateRates(Request $request): JsonResponse
    {
        $request->validate([
            'coins_per_minute' => 'nullable|integer|min:1',
            'female_earning_per_minute' => 'nullable|numeric|min:0',
            'minimum_withdrawal' => 'nullable|numeric|min:0',
        ]);

        foreach ($request->all() as $key => $value) {
            if ($value !== null) {
                Setting::setValue($key, $value);
            }
        }

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'rates_update',
            'description' => 'Updated rate settings',
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Rates updated',
        ]);
    }

    /**
     * Update payment gateway settings
     */
    public function updatePaymentGateway(Request $request): JsonResponse
    {
        $request->validate([
            'active_payment_gateway' => 'required|in:razorpay,payu,cashfree',
        ]);

        Setting::setValue('active_payment_gateway', $request->active_payment_gateway);

        // Log action
        AdminLog::create([
            'admin_id' => $request->user()->id,
            'action' => 'payment_gateway_update',
            'description' => "Changed active payment gateway to: {$request->active_payment_gateway}",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Payment gateway updated',
            'active_gateway' => $request->active_payment_gateway,
        ]);
    }
}
