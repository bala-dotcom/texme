import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../models/chat.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/fcm_service.dart';
import '../../services/notification_service.dart';
import '../../services/online_foreground_service.dart';
import '../../widgets/common/widgets.dart';
import '../chat/chat_screen.dart';
import '../chat/incoming_call_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';
import 'chats_history_screen.dart';

/// Female Home Screen - View males with potential earnings, pending requests
class FemaleHomeScreen extends StatefulWidget {
  const FemaleHomeScreen({super.key});

  @override
  State<FemaleHomeScreen> createState() => _FemaleHomeScreenState();
}

class _FemaleHomeScreenState extends State<FemaleHomeScreen> {
  final ApiService _api = ApiService.instance;
  int _currentIndex = 0;

  List<MaleUser> _males = [];
  List<ChatRequest> _pendingRequests = [];
  bool _isLoading = false;
  bool _isOnline = false;  // Default to false, will load from saved state
  bool _isShowingIncomingCall = false;
  Timer? _pollTimer;
  Timer? _profileTimer;
  final Set<int> _shownRequestIds = {}; // Track already shown requests
  
  static const String _onlineStatusKey = 'female_online_status';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSavedOnlineStatus();  // Load saved status instead of forcing true
    _checkActiveChat(); // Check if user has an active chat
    _startPollingForRequests();
    _setupFcmCallback();  // Set up FCM incoming call callback
    
    // Periodically refresh profile for real-time wallet balance
    _profileTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).refreshProfile();
      }
    });
  }
  
  /// Set up FCM callback to handle incoming calls from foreground messages
  void _setupFcmCallback() {
    FcmService.instance.onIncomingCall = (chatId, callerName, callerAvatar) {
      debugPrint('📞 FCM incoming call received: chatId=$chatId, name=$callerName');
      
      // Check if already showing this call
      if (_shownRequestIds.contains(chatId)) {
        debugPrint('📞 Chat $chatId already shown, skipping');
        return;
      }
      
      // Mark as handled immediately to prevent duplicates
      FcmService.instance.markChatHandled(chatId);
      _shownRequestIds.add(chatId);
      
      // Create ChatRequest and show incoming call screen
      final request = ChatRequest(
        chatId: chatId,
        maleId: 0,  // We don't have this from FCM
        potentialEarning: 0,
        potentialEarningFormatted: '',
        maleName: callerName,
        maleAvatar: callerAvatar,
        requestedAt: DateTime.now(),
      );
      
      _showIncomingCall(request);
    };
    
    // Also set up notification tap callback
    NotificationService.instance.onIncomingCall = (chatId, callerName) {
      debugPrint('📞 Notification tap: chatId=$chatId, name=$callerName');
      
      if (FcmService.instance.wasChatHandled(chatId)) {
        debugPrint('📞 Chat $chatId already handled, skipping notification tap');
        return;
      }
      
      final request = ChatRequest(
        chatId: chatId,
        maleId: 0,
        potentialEarning: 0,
        potentialEarningFormatted: '',
        maleName: callerName,
        maleAvatar: null,
        requestedAt: DateTime.now(),
      );
      
      _shownRequestIds.add(chatId);
      _showIncomingCall(request);
    };
  }
  
  /// Load saved online status from SharedPreferences
  Future<void> _loadSavedOnlineStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStatus = prefs.getBool(_onlineStatusKey) ?? false;  // Default to offline
    await _setOnlineStatus(savedStatus);
  }
  
  /// Save online status to SharedPreferences
  Future<void> _saveOnlineStatus(bool online) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onlineStatusKey, online);
  }

  Future<void> _checkActiveChat() async {
    final response = await _api.getActiveChat();
    
    if (!mounted) return;
    
    if (response.success && response.data != null && response.data['has_active_chat'] == true) {
      final chatData = response.data['chat'];
      if (chatData == null) return;

      final chatId = chatData['id'];
      if (chatId == null) return; // Safety check
      
      final partnerName = chatData['partner']?['name'] ?? 'User';
      final partnerAvatar = chatData['partner']?['avatar'];
      
      // Navigate to active chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: int.tryParse(chatId.toString()) ?? 0,
            partnerName: partnerName,
            partnerAvatar: partnerAvatar,
            isPending: false,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _profileTimer?.cancel();
    // IMPORTANT:
    // Don't automatically set the user offline on dispose; this screen can be disposed
    // when navigating, and we want "Online" to persist (foreground service + FCM).
    super.dispose();
  }

  void _startPollingForRequests() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_isOnline && !_isShowingIncomingCall) {
        _checkForIncomingRequests();
      }
    });
  }

  Future<void> _checkForIncomingRequests() async {
    debugPrint('🔍 Checking for incoming requests... (online: $_isOnline)');
    final response = await _api.getPendingRequests();
    
    if (!mounted) return;
    
    if (response.success && response.data['requests'] != null) {
      final List requests = response.data['requests'];
      debugPrint('🔍 Found ${requests.length} pending requests');
      if (requests.isNotEmpty) {
        final request = ChatRequest.fromJson(requests.first);
        debugPrint('🔍 Request chatId: ${request.chatId}, shown: ${_shownRequestIds.contains(request.chatId)}');
        // Only show if not already shown
        if (!_shownRequestIds.contains(request.chatId)) {
          _shownRequestIds.add(request.chatId);
          debugPrint('🔔 Showing incoming call screen for ${request.maleName}');
          _showIncomingCall(request);
        }
      }
    } else {
      debugPrint('🔍 No pending requests or API error');
    }
  }

  void _showIncomingCall(ChatRequest request) {
    if (_isShowingIncomingCall) return;
    
    setState(() => _isShowingIncomingCall = true);
    
    // Show notification with full-screen intent (for when screen is locked)
    NotificationService.instance.showIncomingCallNotification(
      chatId: request.chatId,
      callerName: request.maleName,
      callerAvatar: request.maleAvatar,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          request: request,
          onDismiss: () {
            // Cancel notification when dismissing
            NotificationService.instance.cancelIncomingCallNotification(request.chatId);
            if (mounted) {
              setState(() => _isShowingIncomingCall = false);
            }
          },
        ),
      ),
    ).then((_) {
      // Cancel notification when screen closes
      NotificationService.instance.cancelIncomingCallNotification(request.chatId);
      if (mounted) {
        setState(() => _isShowingIncomingCall = false);
      }
    });
  }

  Future<void> _setOnlineStatus(bool online) async {
    try {
      final response = await _api.updateOnlineStatus(online);
      if (!response.success) {
        debugPrint('⚠️ Failed to update online status on server: ${response.message}');
        throw Exception('Failed to update status');
      }
      
      if (!mounted) return;

      setState(() => _isOnline = online);

      // Start/stop foreground service for better reliability in background (Android).
      if (online) {
        try {
          await OnlineForegroundService.start();
        } catch (e) {
          debugPrint('⚠️ Error starting foreground service: $e');
          // Continue even if foreground service fails
        }
      } else {
        try {
          await OnlineForegroundService.stop();
          // Clear handled chat IDs when going offline so stale ones don't persist
          FcmService.instance.clearHandledChats();
        } catch (e) {
          debugPrint('⚠️ Error stopping foreground service: $e');
          // Continue even if foreground service fails
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error in _setOnlineStatus: $e');
      rethrow;
    }
  }

  Future<void> _toggleOnlineStatus() async {
    try {
      final newStatus = !_isOnline;
      
      // Check overlay permission when going online
      if (newStatus) {
        try {
          await _checkOverlayPermission();
        } catch (e) {
          debugPrint('⚠️ Error checking overlay permission: $e');
          // Continue even if permission check fails
        }
      }
      
      try {
        await _setOnlineStatus(newStatus);
        await _saveOnlineStatus(newStatus);  // Persist the user's choice
      } catch (e) {
        debugPrint('⚠️ Error setting online status: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update online status. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      
      // Clear tracked requests when going offline so stale ones don't persist
      if (!newStatus) {
        _shownRequestIds.clear();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'You are now Online!' : 'You are now Offline'),
            backgroundColor: newStatus ? AppColors.success : AppColors.textSecondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Critical error in toggleOnlineStatus: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please restart the app.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  /// Check and request overlay permission for incoming call screen on lock screen
  Future<void> _checkOverlayPermission() async {
    try {
      final status = await Permission.systemAlertWindow.status;
      
      if (status.isDenied || status.isPermanentlyDenied) {
        if (!mounted) return;
      
      // Show dialog explaining why we need this permission
      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.phone_callback, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Enable Incoming Calls', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          content: const Text(
            'To receive incoming chat requests even when your phone is locked, please enable "Appear on top" permission.\n\nThis allows the app to show you the incoming call screen without unlocking your phone.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Later', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
      
      if (shouldRequest == true) {
        // Use Android Intent to go directly to overlay permission settings
        try {
          if (Platform.isAndroid) {
            final intent = AndroidIntent(
              action: 'android.settings.action.MANAGE_OVERLAY_PERMISSION',
              data: 'package:com.texme.texme',  // Correct package name
            );
            await intent.launch();
          } else {
            await openAppSettings();
          }
        } catch (e) {
          debugPrint('⚠️ Error launching overlay settings: $e');
          // Silently fail - don't crash the app
        }
      }
      }
    
      // Skip battery optimization check - can cause crashes on some devices
      // Users can enable it manually in settings if needed
    } catch (e) {
      debugPrint('⚠️ Error in overlay permission check: $e');
      // Silently fail - don't crash the app for permission issues
    }
  }
  
  /// Check and request battery optimization exclusion for background notifications
  Future<void> _checkBatteryOptimization() async {
    if (!Platform.isAndroid) return;
    
    final status = await Permission.ignoreBatteryOptimizations.status;
    
    if (status.isDenied) {
      if (!mounted) return;
      
      // Show dialog explaining why we need this permission
      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.battery_charging_full, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Background Notifications', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          content: const Text(
            'To receive incoming calls even when the app is in the background, please disable battery optimization for Texme.\n\nThis ensures you never miss a call!',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Later', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
      
      if (shouldRequest == true) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load pending requests
    final requestsResponse = await _api.getPendingRequests();
    if (requestsResponse.success && requestsResponse.data['requests'] != null) {
      final List requests = requestsResponse.data['requests'];
      setState(() {
        _pendingRequests = requests.map((r) => ChatRequest.fromJson(r)).toList();
      });
    }

    // Load available males
    final malesResponse = await _api.getMales();
    if (malesResponse.success && malesResponse.data['users'] != null) {
      final List users = malesResponse.data['users'];
      setState(() {
        _males = users.map((u) => MaleUser.fromJson(u)).toList();
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _acceptRequest(ChatRequest request) async {
    final response = await _api.acceptChat(request.chatId);

    if (response.success) {
      // Navigate to chat
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: request.chatId,
              partnerName: request.maleName,
              partnerAvatar: request.maleAvatar,
              isPending: false,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to accept'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _declineRequest(ChatRequest request) async {
    final response = await _api.declineChat(request.chatId);

    if (response.success) {
      setState(() {
        _pendingRequests.removeWhere((r) => r.chatId == request.chatId);
      });
    }
  }

  void _showFullScreenRequest(ChatRequest request) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FullScreenChatRequest(
        request: request,
        onAccept: () {
          Navigator.pop(context);
          _acceptRequest(request);
        },
        onDecline: () {
          Navigator.pop(context);
          _declineRequest(request);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(),
            _buildChatsTab(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeTab() {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Logo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Texme', style: AppTextStyles.h3.copyWith(
                color: AppColors.primary,
              )),
              const Spacer(),

              // Wallet Balance
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '₹${(user?.earningBalance ?? 0).toStringAsFixed(0)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),


            ],
          ),
        ),

        // Today's Earnings Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.success, Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Earnings",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '₹${(user?.earningBalance ?? 0).toStringAsFixed(0)}',
                        style: AppTextStyles.h2.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '₹${user?.ratePerMinute ?? 3}/min',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Online/Offline Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: _isOnline 
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: _isOnline ? AppColors.success : AppColors.textSecondary,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Status indicator
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isOnline ? AppColors.success : AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Status text
                    Expanded(
                      child: Text(
                        _isOnline ? 'You are Online' : 'You are Offline',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _isOnline ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Toggle switch
                    Switch(
                      value: _isOnline,
                      onChanged: (_) => _toggleOnlineStatus(),
                      activeColor: AppColors.success,
                      inactiveThumbColor: AppColors.textSecondary,
                      inactiveTrackColor: AppColors.textLight.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Helper note
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  _isOnline 
                      ? '✓ You will receive chat requests from users'
                      : '✗ You will not receive any chat requests',
                  style: AppTextStyles.caption.copyWith(
                    color: _isOnline ? AppColors.success : AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Remaining space
        const Spacer(),
      ],
    );
  }

  Widget _buildChatsTab() {
    return const ChatsHistoryScreen();
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Request Card Widget
class _RequestCard extends StatelessWidget {
  final ChatRequest request;
  final VoidCallback onTap;

  const _RequestCard({
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 4),
                Text(
                  'New Request',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                request.potentialEarningFormatted,
                style: AppTextStyles.h3.copyWith(color: AppColors.success),
              ),
              Text(
                'Tap to view',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      );
    }
}

/// Full Screen Chat Request Dialog
class _FullScreenChatRequest extends StatelessWidget {
  final ChatRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _FullScreenChatRequest({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.primary,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Title
                Text(
                  'INCOMING CHAT',
                  style: AppTextStyles.h2.copyWith(
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // User ID
                Text(
                  'User ID: #${request.maleId}',
                  style: AppTextStyles.h4.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Potential Earning
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Potential Earning',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        request.potentialEarningFormatted,
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Decline Button
                PrimaryButton(
                  text: 'DECLINE',
                  onPressed: onDecline,
                  isOutlined: true,
                ),
                const SizedBox(height: AppSpacing.md),

                // Accept Button
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(
                      'ACCEPT',
                      style: AppTextStyles.button.copyWith(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
