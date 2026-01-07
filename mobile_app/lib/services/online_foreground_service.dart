import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Foreground service wrapper used when a female user toggles "Online".
///
/// Android: keeps the process alive with a persistent notification so incoming
/// calls/FCM handling is more reliable.
class OnlineForegroundService {
  OnlineForegroundService._();

  static const String _channelId = 'texme_online_service';
  static const String _notificationIconMetaData =
      'flutterForegroundTaskNotificationIcon';

  static bool _initialized = false;

  /// Call once during app startup.
  static void init() {
    if (_initialized) return;

    // Foreground service is not supported on web.
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: 'Texme Online',
        channelDescription: 'Keeps Texme online to receive incoming calls',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
        playSound: false,
        showWhen: false,
        showBadge: false,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    _initialized = true;
  }

  static Future<void> start() async {
    if (kIsWeb) return;
    if (!_initialized) init();

    try {
      // Prevent duplicate starts.
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (isRunning) {
        debugPrint('✅ Foreground service already running');
        return;
      }

      await FlutterForegroundTask.startService(
        notificationTitle: 'Texme is Online',
        notificationText: 'Waiting for incoming calls...',
        notificationIcon: const NotificationIcon(
          metaDataName: _notificationIconMetaData,
        ),
        callback: startCallback,
      );
      debugPrint('✅ Foreground service started successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to start foreground service: $e');
      // Silently fail - FCM will still work for notifications
      // Don't rethrow - let the app continue working without foreground service
    }
  }

  static Future<void> stop() async {
    if (kIsWeb) return;
    
    try {
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (!isRunning) {
        debugPrint('✅ Foreground service already stopped');
        return;
      }
      
      await FlutterForegroundTask.stopService();
      debugPrint('✅ Foreground service stopped successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to stop foreground service: $e');
      // Silently fail - don't crash the app
    }
  }
}

/// Foreground task entrypoint.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_OnlineTaskHandler());
}

class _OnlineTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // No periodic network polling here; FCM + local notifications handle calls.
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Intentionally left empty.
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}


