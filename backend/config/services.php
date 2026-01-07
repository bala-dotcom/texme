<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Texme Services
    |--------------------------------------------------------------------------
    */

    // OTP Service Configuration
    'otp' => [
        'provider' => env('OTP_PROVIDER', 'log'), // msg91, 2factor, twilio, log
        'api_key' => env('OTP_API_KEY'),
        'sender_id' => env('OTP_SENDER_ID', 'TEXME'),
        'msg91_template_id' => env('MSG91_TEMPLATE_ID'),
        'twilio_sid' => env('TWILIO_SID'),
        'twilio_token' => env('TWILIO_TOKEN'),
        'twilio_from' => env('TWILIO_FROM'),
    ],

    // Razorpay
    'razorpay' => [
        'key_id' => env('RAZORPAY_KEY_ID'),
        'key_secret' => env('RAZORPAY_KEY_SECRET'),
        'webhook_secret' => env('RAZORPAY_WEBHOOK_SECRET'),
    ],

    // PayU
    'payu' => [
        'merchant_key' => env('PAYU_MERCHANT_KEY'),
        'salt' => env('PAYU_SALT'),
        'mode' => env('PAYU_MODE', 'test'), // test or live
    ],

    // Cashfree
    'cashfree' => [
        'app_id' => env('CASHFREE_APP_ID'),
        'secret_key' => env('CASHFREE_SECRET_KEY'),
        'webhook_secret' => env('CASHFREE_WEBHOOK_SECRET'),
        'mode' => env('CASHFREE_MODE', 'test'), // test or production
    ],

    // Pusher (for real-time)
    'pusher' => [
        'app_id' => env('PUSHER_APP_ID'),
        'app_key' => env('PUSHER_APP_KEY'),
        'app_secret' => env('PUSHER_APP_SECRET'),
        'app_cluster' => env('PUSHER_APP_CLUSTER', 'ap2'),
    ],

    // Firebase Cloud Messaging
    'firebase' => [
        'server_key' => env('FIREBASE_SERVER_KEY'),
    ],

];
