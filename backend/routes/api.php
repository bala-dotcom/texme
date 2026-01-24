<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\CoinController;
use App\Http\Controllers\Api\WalletController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\UserManagementController;
use App\Http\Controllers\Admin\WithdrawalController;
use App\Http\Controllers\Admin\ReportController;
use App\Http\Controllers\Admin\TransactionController;
use App\Http\Controllers\Admin\SettingsController;
use App\Http\Controllers\Admin\CoinPackageController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Health check
Route::get('/health', fn() => response()->json(['status' => 'ok', 'app' => 'Texme API']));

// ========== PUBLIC ROUTES (No Auth Required) ==========
Route::prefix('auth')->group(function () {
    Route::post('/send-otp', [AuthController::class, 'sendOtp']);
    Route::post('/verify-otp', [AuthController::class, 'verifyOtp']);
    Route::post('/truecaller-verify', [AuthController::class, 'truecallerVerify']);
    Route::post('/register', [AuthController::class, 'register']);
});

// Payment webhooks (no auth, verified by signature)
Route::prefix('webhooks')->group(function () {
    Route::post('/razorpay', [PaymentController::class, 'razorpayWebhook']);
    Route::post('/payu', [PaymentController::class, 'payuWebhook']);
    Route::post('/cashfree', [PaymentController::class, 'cashfreeWebhook']);
});

// Coins (Public)
Route::get('/coins/packages', [CoinController::class, 'packages']);

// ========== PROTECTED ROUTES (Auth Required) ==========
Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::prefix('auth')->group(function () {
        Route::get('/profile', [AuthController::class, 'profile']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::post('/online-status', [AuthController::class, 'updateOnlineStatus']);
        Route::post('/fcm-token', [AuthController::class, 'updateFcmToken']);
    });

    // Users
    Route::prefix('users')->group(function () {
        Route::get('/females', [UserController::class, 'listFemales']); // For males
        Route::get('/males', [UserController::class, 'listMales']); // For females (with potential earnings)
        Route::get('/{id}', [UserController::class, 'show'])->where('id', '[0-9]+');
        Route::get('/bank-details', [UserController::class, 'getBankDetails']); // Get bank details (Female only)
        Route::post('/bank-details', [UserController::class, 'updateBankDetails']); // Female only
        Route::get('/random', [UserController::class, 'randomFemale']); // Random connect for males
    });

    // Chat
    Route::prefix('chat')->group(function () {
        // Static routes first (no parameters)
        Route::post('/request', [ChatController::class, 'sendRequest']); // Male sends request
        Route::get('/history', [ChatController::class, 'history']);
        Route::get('/active', [ChatController::class, 'activeChat']);
        Route::get('/pending', [ChatController::class, 'pendingRequests']); // For females

        // Routes with {chatId} parameter
        Route::post('/accept/{chatId}', [ChatController::class, 'accept']); // Female accepts
        Route::post('/decline/{chatId}', [ChatController::class, 'decline']); // Female declines
        Route::get('/{chatId}/status', [ChatController::class, 'getStatus']); // Get chat status
        Route::post('/{chatId}/typing', [ChatController::class, 'setTyping']); // Set typing status
        Route::post('/{chatId}/recording', [ChatController::class, 'setRecording']); // Set recording status
        Route::post('/{chatId}/cancel', [ChatController::class, 'cancel']); // Male cancels request
        Route::post('/{chatId}/message', [ChatController::class, 'sendMessage']);
        Route::post('/{chatId}/voice', [ChatController::class, 'sendVoiceMessage']);
        Route::post('/{chatId}/end', [ChatController::class, 'endChat']);
        Route::post('/{chatId}/charge', [ChatController::class, 'chargeMinute']); // Charge per minute
        Route::get('/{chatId}/messages', [ChatController::class, 'messages']);
    });

    // Coins (Protected)
    Route::prefix('coins')->group(function () {
        Route::get('/balance', [CoinController::class, 'balance']);
        Route::post('/purchase', [CoinController::class, 'initiatePurchase']);
        Route::get('/history', [CoinController::class, 'history']);
    });

    // Wallet (Female users)
    Route::prefix('wallet')->group(function () {
        Route::get('/balance', [WalletController::class, 'balance']);
        Route::get('/history', [WalletController::class, 'history']); // Withdrawal history only
        Route::get('/earnings', [WalletController::class, 'earningHistory']); // Earning history
        Route::post('/withdraw', [WalletController::class, 'requestWithdrawal']);
        Route::get('/withdrawals', [WalletController::class, 'withdrawalHistory']);
    });

    // Reports
    Route::post('/report/user', [UserController::class, 'reportUser']);
    Route::post('/report/message', [ChatController::class, 'reportMessage']);

    // Settings
    Route::get('/settings/app', [UserController::class, 'appSettings']);
});

// ========== ADMIN ROUTES ==========
Route::prefix('admin')->group(function () {

    // Admin auth (public)
    Route::post('/login', [AdminAuthController::class, 'login']);

    // Admin protected routes
    Route::middleware('auth:sanctum')->group(function () {

        // Auth
        Route::post('/logout', [AdminAuthController::class, 'logout']);
        Route::get('/profile', [AdminAuthController::class, 'profile']);
        Route::post('/change-password', [AdminAuthController::class, 'changePassword']);

        // Dashboard
        Route::get('/dashboard/overview', [DashboardController::class, 'overview']);
        Route::get('/dashboard/revenue-chart', [DashboardController::class, 'revenueChart']);
        Route::get('/dashboard/user-chart', [DashboardController::class, 'userChart']);
        Route::get('/dashboard/recent', [DashboardController::class, 'recentActivities']);

        // User Management
        Route::prefix('users')->group(function () {
            Route::get('/', [UserManagementController::class, 'index']);
            Route::get('/pending-females', [UserManagementController::class, 'pendingFemales']);
            Route::get('/{id}', [UserManagementController::class, 'show']);
            Route::put('/{id}', [UserManagementController::class, 'update']);
            Route::put('/{id}/status', [UserManagementController::class, 'updateStatus']);
            Route::post('/{id}/approve', [UserManagementController::class, 'approveFemale']);
            Route::post('/{id}/reject', [UserManagementController::class, 'rejectFemale']);
            Route::post('/{id}/add-coins', [UserManagementController::class, 'addCoins']);
        });

        // Voice Verifications
        Route::prefix('voice-verifications')->group(function () {
            Route::get('/', [UserManagementController::class, 'voiceVerifications']);
            Route::post('/{id}/verify', [UserManagementController::class, 'verifyVoice']);
            Route::post('/{id}/reject', [UserManagementController::class, 'rejectVoice']);
        });

        // Withdrawals
        Route::prefix('withdrawals')->group(function () {
            Route::get('/', [WithdrawalController::class, 'index']);
            Route::get('/pending', [WithdrawalController::class, 'pending']);
            Route::get('/{id}', [WithdrawalController::class, 'show']);
            Route::post('/{id}/approve', [WithdrawalController::class, 'approve']);
            Route::post('/{id}/complete', [WithdrawalController::class, 'complete']);
            Route::post('/{id}/reject', [WithdrawalController::class, 'reject']);
        });

        // Reports
        Route::prefix('reports')->group(function () {
            Route::get('/', [ReportController::class, 'index']);
            Route::get('/pending', [ReportController::class, 'pending']);
            Route::get('/{id}', [ReportController::class, 'show']);
            Route::post('/{id}/dismiss', [ReportController::class, 'dismiss']);
            Route::post('/{id}/warn', [ReportController::class, 'warn']);
            Route::post('/{id}/suspend', [ReportController::class, 'suspend']);
            Route::post('/{id}/ban', [ReportController::class, 'ban']);
        });

        // Transactions
        Route::prefix('transactions')->group(function () {
            Route::get('/', [TransactionController::class, 'index']);
            Route::get('/summary', [TransactionController::class, 'summary']);
            Route::get('/export', [TransactionController::class, 'export']);
            Route::get('/{id}', [TransactionController::class, 'show']);
        });

        // Settings
        Route::prefix('settings')->group(function () {
            Route::get('/', [SettingsController::class, 'index']);
            Route::post('/update', [SettingsController::class, 'update']);
            Route::post('/coin-packages', [SettingsController::class, 'updateCoinPackages']);
            Route::post('/rates', [SettingsController::class, 'updateRates']);
            Route::post('/payment-gateway', [SettingsController::class, 'updatePaymentGateway']);
            Route::post('/legal', [SettingsController::class, 'updateLegalContent']);
        });

        // Coin Packages
        Route::apiResource('coin-packages', CoinPackageController::class);
    });
});
