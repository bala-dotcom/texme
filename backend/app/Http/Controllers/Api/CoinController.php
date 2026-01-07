<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Transaction;
use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class CoinController extends Controller
{
    /**
     * Get coin balance (male only)
     */
    public function balance(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isMale()) {
            return response()->json([
                'success' => false,
                'message' => 'This feature is for male users only',
            ], 403);
        }

        return response()->json([
            'success' => true,
            'balance' => $user->coin_balance,
            'total_purchased' => $user->total_coins_purchased,
            'total_spent' => $user->total_coins_spent,
        ]);
    }

    /**
     * Get available coin packages
     */
    public function packages(Request $request): JsonResponse
    {
        $packages = Setting::getCoinPackages();

        return response()->json([
            'success' => true,
            'packages' => $packages,
            'active_gateway' => Setting::getActivePaymentGateway(),
        ]);
    }

    /**
     * Initiate coin purchase
     */
    public function initiatePurchase(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isMale()) {
            return response()->json([
                'success' => false,
                'message' => 'This feature is for male users only',
            ], 403);
        }

        $request->validate([
            'package_index' => 'required|integer|min:0',
        ]);

        $packages = Setting::getCoinPackages();
        
        if (!isset($packages[$request->package_index])) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid package',
            ], 400);
        }

        $package = $packages[$request->package_index];
        $gateway = Setting::getActivePaymentGateway();

        // Create pending transaction
        $transaction = Transaction::create([
            'user_id' => $user->id,
            'type' => 'coin_purchase',
            'amount' => $package['price'],
            'coins' => $package['coins'] + ($package['bonus'] ?? 0),
            'gateway' => $gateway,
            'status' => 'pending',
        ]);

        // Generate order based on gateway
        $orderData = $this->createGatewayOrder($gateway, $transaction, $package);

        if (!$orderData) {
            $transaction->markAsFailed();
            return response()->json([
                'success' => false,
                'message' => 'Failed to create payment order',
            ], 500);
        }

        $transaction->gateway_order_id = $orderData['order_id'];
        $transaction->save();

        return response()->json([
            'success' => true,
            'transaction_id' => $transaction->id,
            'gateway' => $gateway,
            'order' => $orderData,
        ]);
    }

    /**
     * Get coin transaction history
     */
    public function history(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->isMale()) {
            return response()->json([
                'success' => false,
                'message' => 'This feature is for male users only',
            ], 403);
        }

        $transactions = Transaction::where('user_id', $user->id)
            ->whereIn('type', ['coin_purchase', 'coin_deduction'])
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'transactions' => $transactions->map(fn($t) => [
                'id' => $t->id,
                'type' => $t->type,
                'amount' => $t->amount,
                'coins' => $t->coins,
                'status' => $t->status,
                'created_at' => $t->created_at,
            ]),
            'pagination' => [
                'current_page' => $transactions->currentPage(),
                'last_page' => $transactions->lastPage(),
                'total' => $transactions->total(),
            ],
        ]);
    }

    /**
     * Create order with payment gateway
     */
    private function createGatewayOrder(string $gateway, Transaction $transaction, array $package): ?array
    {
        try {
            switch ($gateway) {
                case 'razorpay':
                    return $this->createRazorpayOrder($transaction, $package);
                case 'payu':
                    return $this->createPayuOrder($transaction, $package);
                case 'cashfree':
                    return $this->createCashfreeOrder($transaction, $package);
                default:
                    return null;
            }
        } catch (\Exception $e) {
            \Log::error("Payment gateway error: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Create Razorpay order
     */
    private function createRazorpayOrder(Transaction $transaction, array $package): array
    {
        $keyId = config('services.razorpay.key_id');
        $keySecret = config('services.razorpay.key_secret');

        $api = new \Razorpay\Api\Api($keyId, $keySecret);

        $order = $api->order->create([
            'receipt' => 'txn_' . $transaction->id,
            'amount' => $package['price'] * 100, // In paise
            'currency' => 'INR',
            'notes' => [
                'user_id' => $transaction->user_id,
                'coins' => $transaction->coins,
            ],
        ]);

        return [
            'order_id' => $order->id,
            'amount' => $package['price'] * 100,
            'currency' => 'INR',
            'key_id' => $keyId,
            'name' => 'Texme',
            'description' => $package['label'] . ' - ' . $transaction->coins . ' Coins',
        ];
    }

    /**
     * Create PayU order
     */
    private function createPayuOrder(Transaction $transaction, array $package): array
    {
        $merchantKey = config('services.payu.merchant_key');
        $salt = config('services.payu.salt');

        $txnId = 'TXN' . $transaction->id . time();
        $amount = $package['price'];
        $productInfo = $package['label'] . ' - ' . $transaction->coins . ' Coins';

        $hashString = $merchantKey . '|' . $txnId . '|' . $amount . '|' . $productInfo . '|' . 
                      $transaction->user->name . '|' . $transaction->user->email . '|||||||||||' . $salt;
        $hash = strtolower(hash('sha512', $hashString));

        return [
            'order_id' => $txnId,
            'hash' => $hash,
            'key' => $merchantKey,
            'amount' => $amount,
            'productinfo' => $productInfo,
            'firstname' => $transaction->user->name,
            'email' => $transaction->user->email ?? 'user@texme.app',
            'phone' => $transaction->user->phone,
        ];
    }

    /**
     * Create Cashfree order
     */
    private function createCashfreeOrder(Transaction $transaction, array $package): array
    {
        $appId = config('services.cashfree.app_id');
        $secretKey = config('services.cashfree.secret_key');

        $orderId = 'CF_' . $transaction->id . '_' . time();

        $response = \Http::withHeaders([
            'x-client-id' => $appId,
            'x-client-secret' => $secretKey,
            'Content-Type' => 'application/json',
        ])->post('https://api.cashfree.com/pg/orders', [
            'order_id' => $orderId,
            'order_amount' => $package['price'],
            'order_currency' => 'INR',
            'customer_details' => [
                'customer_id' => 'user_' . $transaction->user_id,
                'customer_phone' => $transaction->user->phone,
            ],
        ]);

        if ($response->successful()) {
            $data = $response->json();
            return [
                'order_id' => $orderId,
                'payment_session_id' => $data['payment_session_id'] ?? null,
                'order_token' => $data['order_token'] ?? null,
            ];
        }

        throw new \Exception('Cashfree order creation failed');
    }
}
