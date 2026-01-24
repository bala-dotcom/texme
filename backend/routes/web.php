<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/privacy-policy', function () {
    $content = \App\Models\Setting::getValue('privacy_policy_content');
    return view('privacy-policy', ['content' => $content]);
});

Route::get('/terms-of-service', function () {
    $content = \App\Models\Setting::getValue('terms_of_service_content');
    return view('terms', ['content' => $content]);
});
