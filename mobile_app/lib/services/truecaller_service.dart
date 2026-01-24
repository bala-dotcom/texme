import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:truecaller_sdk/truecaller_sdk.dart';

/// TruecallerService - Handles Truecaller SDK integration for phone verification
class TruecallerService {
  static final TruecallerService _instance = TruecallerService._internal();
  factory TruecallerService() => _instance;
  TruecallerService._internal();

  StreamSubscription? _streamSubscription;
  String? _oAuthState;
  String? _codeVerifier;
  
  // Callbacks
  Function(TruecallerResult)? onResult;

  /// Initialize the Truecaller SDK
  Future<void> initialize() async {
    try {
      // Initialize SDK with option to verify only Truecaller users
      // Non-Truecaller users will fall back to OTP
      TcSdk.initializeSDK(
        sdkOption: TcSdkOptions.OPTION_VERIFY_ONLY_TC_USERS,
      );
      debugPrint('✅ Truecaller SDK initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Truecaller SDK: $e');
    }
  }

  /// Check if Truecaller OAuth flow is available on this device
  Future<bool> isAvailable() async {
    try {
      final isUsable = await TcSdk.isOAuthFlowUsable;
      debugPrint('🔍 Truecaller isOAuthFlowUsable: $isUsable');
      return isUsable;
    } catch (e) {
      debugPrint('❌ Error checking Truecaller availability: $e');
      return false;
    }
  }

  /// Start Truecaller authentication flow
  Future<void> startVerification() async {
    try {
      final isUsable = await TcSdk.isOAuthFlowUsable;
      
      if (!isUsable) {
        debugPrint('❌ Truecaller OAuth not usable on this device');
        onResult?.call(TruecallerResult.notAvailable());
        return;
      }

      // Generate unique OAuth state
      _oAuthState = DateTime.now().millisecondsSinceEpoch.toString();
      TcSdk.setOAuthState(_oAuthState!);
      
      // Set OAuth scopes - Added openid which is usually required for OAuth2 profile fetching
      TcSdk.setOAuthScopes(['phone', 'openid']);
      
      // Generate code verifier and challenge for PKCE
      _codeVerifier = await TcSdk.generateRandomCodeVerifier;
      
      if (_codeVerifier != null) {
        final codeChallenge = await TcSdk.generateCodeChallenge(_codeVerifier!);
        
        if (codeChallenge != null) {
          TcSdk.setCodeChallenge(codeChallenge);
          
          // Listen for callback
          _setupCallbackListener();
          
          // Trigger the OAuth consent screen
          TcSdk.getAuthorizationCode;
          debugPrint('🚀 Truecaller OAuth flow started');
        } else {
          debugPrint('❌ Failed to generate code challenge');
          onResult?.call(TruecallerResult.error('Failed to generate code challenge'));
        }
      } else {
        debugPrint('❌ Failed to generate code verifier');
        onResult?.call(TruecallerResult.error('Failed to generate code verifier'));
      }
    } catch (e) {
      debugPrint('❌ Error starting Truecaller verification: $e');
      onResult?.call(TruecallerResult.error(e.toString()));
    }
  }

  /// Setup callback listener for Truecaller SDK responses
  void _setupCallbackListener() {
    _streamSubscription?.cancel();
    _streamSubscription = TcSdk.streamCallbackData.listen((tcSdkCallback) {
      debugPrint('📱 Truecaller callback: ${tcSdkCallback.result}');
      
      switch (tcSdkCallback.result) {
        case TcSdkCallbackResult.success:
          final tcOAuthData = tcSdkCallback.tcOAuthData;
          if (tcOAuthData != null) {
            debugPrint('✅ Truecaller success - authCode: ${tcOAuthData.authorizationCode}');
            onResult?.call(TruecallerResult.success(
              authorizationCode: tcOAuthData.authorizationCode,
              codeVerifier: _codeVerifier!,
              state: tcOAuthData.state,
            ));
          } else {
            onResult?.call(TruecallerResult.error('No OAuth data received'));
          }
          break;
          
        case TcSdkCallbackResult.failure:
          final error = tcSdkCallback.error;
          debugPrint('❌ Truecaller failure - code: ${error?.code}, message: ${error?.message}');
          onResult?.call(TruecallerResult.error(
            '${error?.message ?? 'Verification failed'} (Error: ${error?.code})'
          ));
          break;
          
        case TcSdkCallbackResult.verification:
          // This won't be called since we use OPTION_VERIFY_ONLY_TC_USERS
          debugPrint('⚠️ Verification required (non-Truecaller user)');
          onResult?.call(TruecallerResult.notAvailable());
          break;
          
        default:
          debugPrint('❓ Unknown callback result');
          onResult?.call(TruecallerResult.error('Unknown result'));
      }
    });
  }

  /// Clean up resources
  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    onResult = null;
  }
}

/// Result class for Truecaller verification
class TruecallerResult {
  final bool isSuccess;
  final bool isNotAvailable;
  final String? authorizationCode;
  final String? codeVerifier;
  final String? state;
  final String? error;

  TruecallerResult._({
    required this.isSuccess,
    required this.isNotAvailable,
    this.authorizationCode,
    this.codeVerifier,
    this.state,
    this.error,
  });

  factory TruecallerResult.success({
    required String authorizationCode,
    required String codeVerifier,
    String? state,
  }) {
    return TruecallerResult._(
      isSuccess: true,
      isNotAvailable: false,
      authorizationCode: authorizationCode,
      codeVerifier: codeVerifier,
      state: state,
    );
  }

  factory TruecallerResult.error(String message) {
    return TruecallerResult._(
      isSuccess: false,
      isNotAvailable: false,
      error: message,
    );
  }

  factory TruecallerResult.notAvailable() {
    return TruecallerResult._(
      isSuccess: false,
      isNotAvailable: true,
    );
  }
}
