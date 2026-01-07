<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    /**
     * Razorpay webhook handler
     */
    public function razorpayWebhook(Request $request): JsonResponse
    {
        $payload = $request->all();
        $webhookSecret = config('services.razorpay.webhook_secret');
        
        // Verify signature
        $signature = $request->header('X-Razorpay-Signature');
        $expectedSignature = hash_hmac('sha256', $request->getContent(), $webhookSecret);
        
        if (!hash_equals($expectedSignature, $signature ?? '')) {
            Log::warning('Razorpay webhook: Invalid signature');
            return response()->json(['error' => 'Invalid signature'], 401);
        }

        $event = $payload['event'] ?? '';

        switch ($event) {
            case 'payment.captured':
                $this->handleRazorpayPaymentCaptured($payload);
                break;
            case 'payment.failed':
                $this->handleRazorpayPaymentFailed($payload);
                break;
        }

        return response()->json(['status' => 'ok']);
    }

    /**
     * PayU webhook handler
     */
    public function payuWebhook(Request $request): JsonResponse
    {
        $payload = $request->all();
        
        // Verify hash
        $salt = config('services.payu.salt');
        $status = $payload['status'] ?? '';
        $txnid = $payload['txnid'] ?? '';
        $amount = $payload['amount'] ?? '';
        $productinfo = $payload['productinfo'] ?? '';
        $firstname = $payload['firstname'] ?? '';
        $email = $payload['email'] ?? '';
        
        $keyString = $salt . '|' . $status . '||||||||||' . $email . '|' . $firstname . '|' . $productinfo . '|' . $amount . '|' . $txnid . '|' . config('services.payu.merchant_key');
        $expectedHash = strtolower(hash('sha512', $keyString));
        
        if (!hash_equals($expectedHash, $payload['hash'] ?? '')) {
            Log::warning('PayU webhook: Invalid hash');
            return response()->json(['error' => 'Invalid hash'], 401);
        }

        // Extract transaction ID from txnid (format: TXN{id}{timestamp})
        preg_match('/TXN(\d+)/', $txnid, $matches);
        $transactionId = $matches[1] ?? null;

        if (!$transactionId) {
            return response()->json(['error' => 'Invalid transaction'], 400);
        }

        $transaction = Transaction::find($transactionId);

        if (!$transaction) {
            return response()->json(['error' => 'Transaction not found'], 404);
        }

        if ($status === 'success') {
            $this->creditCoins($transaction, $payload['mihpayid'] ?? null);
        } else {
            $transaction->markAsFailed();
        }

        return response()->json(['status' => 'ok']);
    }

    /**
     * Cashfree webhook handler
     */
    public function cashfreeWebhook(Request $request): JsonResponse
    {
        $payload = $request->all();
        
        // Verify signature
        $signature = $request->header('x-webhook-signature');
        $webhookSecret = config('services.cashfree.webhook_secret');
        $expectedSignature = base64_encode(hash_hmac('sha256', $request->getContent(), $webhookSecret, true));
        
        if (!hash_equals($expectedSignature, $signature ?? '')) {
            Log::warning('Cashfree webhook: Invalid signature');
            return response()->json(['error' => 'Invalid signature'], 401);
        }

        $event = $payload['type'] ?? '';
        $orderData = $payload['data']['order'] ?? [];
        $paymentData = $payload['data']['payment'] ?? [];

        // Extract transaction ID from order_id (format: CF_{id}_{timestamp})
        preg_match('/CF_(\d+)_/', $orderData['order_id'] ?? '', $matches);
        $transactionId = $matches[1] ?? null;

        if (!$transactionId) {
            return response()->json(['error' => 'Invalid order'], 400);
        }

        $transaction = Transaction::find($transactionId);

        if (!$transaction) {
            return response()->json(['error' => 'Transaction not found'], 404);
        }

        if ($event === 'PAYMENT_SUCCESS') {
            $this->creditCoins($transaction, $paymentData['cf_payment_id'] ?? null);
        } elseif ($event === 'PAYMENT_FAILED') {
            $transaction->markAsFailed();
        }

        return response()->json(['status' => 'ok']);
    }

    /**
     * Handle Razorpay payment captured
     */
    private function handleRazorpayPaymentCaptured(array $payload): void
    {
        $payment = $payload['payload']['payment']['entity'] ?? [];
        $orderId = $payment['order_id'] ?? null;

        if (!$orderId) return;

        $transaction = Transaction::where('gateway_order_id', $orderId)->first();

        if (!$transaction || $transaction->status === 'success') return;

        $this->creditCoins($transaction, $payment['id'] ?? null);
    }

    /**
     * Handle Razorpay payment failed
     */
    private function handleRazorpayPaymentFailed(array $payload): void
    {
        $payment = $payload['payload']['payment']['entity'] ?? [];
        $orderId = $payment['order_id'] ?? null;

        if (!$orderId) return;

        $transaction = Transaction::where('gateway_order_id', $orderId)->first();

        if (!$transaction || $transaction->status !== 'pending') return;

        $transaction->markAsFailed();
    }

    /**
     * Credit coins to user after successful payment
     */
    private function creditCoins(Transaction $transaction, ?string $paymentId): void
    {
        if ($transaction->status === 'success') {
            return; // Already processed
        }

        $transaction->gateway_payment_id = $paymentId;
        $transaction->markAsSuccess();

        $user = $transaction->user;
        $user->coin_balance += $transaction->coins;
        $user->total_coins_purchased += $transaction->coins;
        $user->save();

        Log::info("Credited {$transaction->coins} coins to user {$user->id}");
    }
}
