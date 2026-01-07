import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';
import 'notification_service.dart';

/// Background message handler - must be top-level function
/// This runs when app is in background or killed
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Initialize Firebase first
    await Firebase.initializeApp();
    
    print('🔥 [BACKGROUND] Message received: ${message.messageId}');
    print('🔥 [BACKGROUND] Message data: ${message.data}');
    
    // Handle incoming call notification
    if (message.data['type'] == 'incoming_call') {
      final chatId = int.tryParse(message.data['chat_id'] ?? '0') ?? 0;
      final callerName = message.data['caller_name'] ?? 'Unknown';
      final callerAvatar = message.data['caller_avatar'];
      
      print('🔥 [BACKGROUND] Incoming call: chatId=$chatId, name=$callerName');
      
      // Initialize notification service
      await NotificationService.instance.initialize();
      
      // Show the notification with full-screen intent
      await NotificationService.instance.showIncomingCallNotification(
        chatId: chatId,
        callerName: callerName,
        callerAvatar: callerAvatar,
      );
      
      print('🔥 [BACKGROUND] Notification shown for chat $chatId');
    }
  } catch (e, stackTrace) {
    print('🔥 [BACKGROUND] Error: $e');
    print('🔥 [BACKGROUND] Stack: $stackTrace');
  }
}

/// FCM Service for handling Firebase Cloud Messaging
class FcmService {
  static final FcmService _instance = FcmService._();
  static FcmService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _api = ApiService.instance;

  bool _initialized = false;
  String? _fcmToken;
  
  // Track chat IDs that were already handled to prevent duplicates
  final Set<int> _handledChatIds = {};

  // Callback for when incoming call is received via FCM (foreground)
  Function(int chatId, String callerName, String? callerAvatar)? onIncomingCall;

  FcmService._();

  String? get fcmToken => _fcmToken;
  
  /// Check if a chat was already handled
  bool wasChatHandled(int chatId) => _handledChatIds.contains(chatId);
  
  /// Mark a chat as handled
  void markChatHandled(int chatId) => _handledChatIds.add(chatId);
  
  /// Clear handled chat IDs (e.g., when going offline)
  void clearHandledChats() => _handledChatIds.clear();

  Future<void> initialize() async {
    if (_initialized) return;

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    debugPrint('🔥 FCM Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      
      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('🔥 FCM Token: $_fcmToken');

      // Send token to backend
      if (_fcmToken != null) {
        await _updateTokenOnServer(_fcmToken!);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('🔥 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        await _updateTokenOnServer(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    }

    _initialized = true;
    debugPrint('🔥 FCM Service initialized');
  }

  Future<void> _updateTokenOnServer(String token) async {
    try {
      final response = await _api.updateFcmToken(token);
      if (response.success) {
        debugPrint('🔥 FCM token updated on server');
      } else {
        debugPrint('🔥 Failed to update FCM token: ${response.message}');
      }
    } catch (e) {
      debugPrint('🔥 Error updating FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔥 Foreground message: ${message.messageId}');
    debugPrint('🔥 Message data: ${message.data}');

    if (message.data['type'] == 'incoming_call') {
      final chatId = int.tryParse(message.data['chat_id'] ?? '0') ?? 0;
      final callerName = message.data['caller_name'] ?? 'Unknown';
      final callerAvatar = message.data['caller_avatar'];

      // Check if already handled (prevent duplicates)
      if (_handledChatIds.contains(chatId)) {
        debugPrint('🔥 Chat $chatId already handled, skipping');
        return;
      }

      // Notify the app about incoming call (to show IncomingCallScreen)
      // The callback will mark it as handled after showing the screen
      onIncomingCall?.call(chatId, callerName, callerAvatar);

      // Also show notification in case user doesn't see it
      NotificationService.instance.showIncomingCallNotification(
        chatId: chatId,
        callerName: callerName,
        callerAvatar: callerAvatar,
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔥 Notification tapped: ${message.messageId}');
    debugPrint('🔥 Message data: ${message.data}');

    if (message.data['type'] == 'incoming_call') {
      final chatId = int.tryParse(message.data['chat_id'] ?? '0') ?? 0;
      final callerName = message.data['caller_name'] ?? 'Unknown';
      final callerAvatar = message.data['caller_avatar'];

      // Mark as handled
      markChatHandled(chatId);

      // Navigate to incoming call screen
      onIncomingCall?.call(chatId, callerName, callerAvatar);
    }
  }

  /// Delete FCM token (for logout)
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
    _fcmToken = null;
    debugPrint('🔥 FCM token deleted');
  }
}
