import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification Service for handling incoming call notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Function(int chatId, String callerName)? onIncomingCall;

  NotificationService._();

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the incoming calls notification channel with high importance
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Request notification permission for Android 13+
        await androidPlugin.requestNotificationsPermission();
        
        // Delete old channel to ensure new settings are applied
        await androidPlugin.deleteNotificationChannel('incoming_calls');
        debugPrint('🔔 Deleted old incoming_calls channel (if existed)');
        
        // Create notification channel with full-screen intent support
        const channel = AndroidNotificationChannel(
          'incoming_calls',
          'Incoming Calls',
          description: 'Notifications for incoming chat requests',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        
        await androidPlugin.createNotificationChannel(channel);
        debugPrint('🔔 Created incoming_calls notification channel');
      }
    }

    _initialized = true;
    debugPrint('🔔 NotificationService initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    debugPrint('🔔 Action ID: ${response.actionId}');
    
    if (response.payload != null) {
      // Parse payload: "chatId:123:callerName:John"
      final parts = response.payload!.split(':');
      if (parts.length >= 4 && parts[0] == 'chatId') {
        final chatId = int.tryParse(parts[1]) ?? 0;
        final callerName = parts[3];
        debugPrint('🔔 Parsed: chatId=$chatId, name=$callerName');
        onIncomingCall?.call(chatId, callerName);
      }
    }
  }

  /// Show incoming call notification with full-screen intent
  Future<void> showIncomingCallNotification({
    required int chatId,
    required String callerName,
    String? callerAvatar,
  }) async {
    debugPrint('🔔 Showing incoming call notification: chatId=$chatId, name=$callerName');
    
    const androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'Notifications for incoming chat requests',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true, // Shows on lock screen
      ongoing: true, // Can't be swiped away
      autoCancel: false,
      playSound: true,
      enableVibration: true,
      timeoutAfter: 60000, // 60 seconds timeout
      colorized: true,
      color: Color(0xFF26A69A), // Teal color
      actions: [
        AndroidNotificationAction(
          'accept',
          'Accept',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'decline',
          'Decline',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      chatId, // Use chatId as notification ID
      '📞 Incoming Call',
      '$callerName wants to chat with you',
      details,
      payload: 'chatId:$chatId:callerName:$callerName',
    );

    debugPrint('🔔 Incoming call notification shown for chat $chatId');
  }

  /// Cancel incoming call notification
  Future<void> cancelIncomingCallNotification(int chatId) async {
    await _notifications.cancel(chatId);
    debugPrint('🔔 Cancelled notification for chat $chatId');
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
