import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/chat.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/voice_service.dart';
import '../../widgets/common/widgets.dart';
import '../../main.dart';
import '../home/home_screen.dart';
import '../wallet/coin_purchase_screen.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';

/// Chat Screen
class ChatScreen extends StatefulWidget {
  final int chatId;
  final String partnerName;
  final String? partnerAvatar;
  final bool isPending;
  final double? ratePerMinute;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.partnerName,
    this.partnerAvatar,
    this.isPending = false,
    this.ratePerMinute,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _api = ApiService.instance;
  final VoiceService _voiceService = VoiceService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isPending = false;
  bool _isSending = false;

  // Voice recording state
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  Timer? _refreshTimer;
  Timer? _billingTimer;
  int _chatMinutes = 0;
  int _coinsSpent = 0;
  bool _isPartnerTyping = false;
  bool _isPartnerRecording = false;
  DateTime? _lastTypingSent;
  DateTime? _lastRecordingSent;
  double? _rate;
  Timer? _countdownTimer;
  int _remainingSeconds = -1; // -1 means sync is pending
  static const _securityChannel = MethodChannel('com.texme.app/security');

  @override
  void initState() {
    super.initState();
    _isPending = widget.isPending;
    _rate = widget.ratePerMinute;
    if (!_isPending) {
      _loadMessages();
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isMale) {
        _startBilling(); // Start billing immediately
      }
      _startCountdown(); // Start HH:MM:SS countdown for both
    }
    _startUpdates();
    _secureScreen();
    _initScreenshotDetection();
  }

  Future<void> _secureScreen() async {
    try {
      if (Platform.isAndroid) {
        debugPrint('🛡️ Enabling FLAG_SECURE via MethodChannel');
        await _securityChannel.invokeMethod('enableSecure');
        debugPrint('🛡️ FLAG_SECURE enabled');
      }
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageWithColor(AppColors.primary);
    } catch (e) {
      debugPrint('❌ Security Error in _secureScreen: $e');
    }
  }

  Future<void> _clearSecureScreen() async {
    try {
      if (Platform.isAndroid) {
        debugPrint('🛡️ Disabling FLAG_SECURE via MethodChannel');
        await _securityChannel.invokeMethod('disableSecure');
        debugPrint('🛡️ FLAG_SECURE disabled');
      }
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
    } catch (e) {
      debugPrint('❌ Security Error in _clearSecureScreen: $e');
    }
  }

  void _initScreenshotDetection() {
    ScreenProtector.addListener(() {
      _showScreenshotToast();
    }, (isCaptured) {
      if (isCaptured) {
        _showScreenshotToast();
      }
    });
  }

  void _showScreenshotToast() {
    Fluttertoast.showToast(
      msg: "this app also did take a screen shot",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    
    // Initial calculation
    _syncRemainingTime();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else if (_remainingSeconds == 0 && !_isPending) {
          // Time's up!
          _countdownTimer?.cancel();
          _handleOutOfCoins();
        }
        // If _remainingSeconds is -1, we are still waiting for initial sync
      });
    });
  }

  void _syncRemainingTime() {
    // Only sync on initial load (when _remainingSeconds is -1)
    if (_remainingSeconds != -1) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isMale) {
      final coins = auth.user?.coinBalance ?? 0;
      const rate = 10.0; // Fixed rate as per configuration: 10 coins = 1 minute
      _remainingSeconds = ((coins / rate) * 60).floor();
    }
    // Female handles sync via _loadChatStatus from backend
  }

  void _handleOutOfCoins() {
    if (!mounted) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isMale) {
      _showInsufficientCoinsDialog();
    } else {
      // Female: show chat ended dialog (partner ran out of coins)
      _showChatEndedDialog();
    }
  }

  void _showInsufficientCoinsDialog() {
    if (!mounted) return;
    
    _endChat(); // End the chat first
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have not enough coins'),
        backgroundColor: AppColors.warning,
        duration: Duration(seconds: 3),
      ),
    );
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CoinPurchaseScreen()),
    );
  }

  String _formatHHMMSS(int totalSeconds) {
    if (totalSeconds <= 0) return "00:00:00";
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    _billingTimer?.cancel();
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _voiceService.cancelRecording();
    _clearSecureScreen();
    ScreenProtector.removeListener();
    super.dispose();
  }

  void _startUpdates() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_isPending) {
        _loadMessages();
        _loadChatStatus();
      } else {
        _checkRequestStatus();
      }
    });
  }

  void _startBilling() {
    // First charge after 10 seconds free trial
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      _chargeMinute();
      
      // Then charge every 60 seconds (1 minute) after the first charge
      _billingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        _chargeMinute();
      });
    });
  }

  Future<void> _chargeMinute() async {
    final response = await _api.chargeMinute(widget.chatId);
    
    if (!mounted) return;
    
    if (response.success) {
      if (mounted) {
        setState(() {
          _chatMinutes = response.data['total_minutes'] ?? _chatMinutes + 1;
          _coinsSpent = response.data['total_coins_spent'] ?? _coinsSpent;
        });
        
        // Refresh global profile to update coin/wallet balance in header/home
        Provider.of<AuthProvider>(context, listen: false).refreshProfile();
        // Note: We do NOT call _syncRemainingTime here - the countdown runs client-side
      }
    } else if (response.data?['chat_ended'] == true) {
      // Chat ended due to insufficient coins
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isMale) {
        _showInsufficientCoinsDialog();
      } else {
        _showChatEndedDialog();
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_isLoading) return;

    final response = await _api.getChatMessages(widget.chatId);

    if (response.success && response.data['messages'] != null) {
      final List msgs = response.data['messages'];
      final newMessages = msgs.map((m) => Message.fromJson(m)).toList();
      
      // Debug: log voice messages
      for (var msg in newMessages) {
        if (msg.isVoice) {
          debugPrint('📥 Loaded voice message id=${msg.id}, voiceUrl=${msg.voiceUrl}');
        }
      }
      
      setState(() {
        // Keep optimistic messages that are still sending or failed
        final optimisticMessages = _messages.where((m) => m.isSending || m.isFailed).toList();
        
        _messages = newMessages;
        
        // Add back optimistic messages if they aren't already in the new list (by matching content/type)
        for (var opt in optimisticMessages) {
          bool alreadyExists = _messages.any((m) => 
            m.senderId == opt.senderId && 
            m.type == opt.type && 
            (m.content == opt.content || m.voiceDuration == opt.voiceDuration)
          );
          if (!alreadyExists) {
            _messages.add(opt);
          }
        }
        
        // Sort by time just in case
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });

      _scrollToBottom();
    }
  }

  Future<void> _loadChatStatus() async {
    // Use getChatStatus to check the specific chat, not getActiveChat
    final response = await _api.getChatStatus(widget.chatId);

    if (!mounted) return;

    if (response.success) {
      final status = response.data['status'];
      final isTyping = response.data['is_typing'] ?? false;
      final isRecording = response.data['is_recording'] ?? false;
      
      if (mounted) {
        setState(() {
          _isPartnerTyping = isTyping;
          _isPartnerRecording = isRecording;
          if (_rate == null && response.data['partner']?['rate_per_minute'] != null) {
            _rate = double.tryParse(response.data['partner']['rate_per_minute'].toString());
          }
          
          // Sync remaining seconds from backend ONLY for the first time (initial sync)
          // After that, the client-side timer handles the countdown
          if (response.data['remaining_seconds'] != null && _remainingSeconds == -1) {
            _remainingSeconds = int.tryParse(response.data['remaining_seconds'].toString()) ?? 0;
          }
        });
      }
      
      if (status == 'ended' || status == 'declined' || status == 'cancelled') {
        // Chat ended
        _showChatEndedDialog();
      }
      // If pending, do nothing - wait for it to become active
    }
  }

  Future<void> _checkRequestStatus() async {
    final response = await _api.getActiveChat();

    if (response.success && response.data['has_active_chat'] == true) {
      // Request accepted!
      setState(() => _isPending = false);
      _loadMessages();
      
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isMale) {
        _startBilling();
      }
      _startCountdown();
    }
  }

  Future<void> _sendMessage() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final tempMessage = Message.optimistic(
      senderId: auth.user?.id ?? 0,
      content: text,
      type: 'text',
    );

    setState(() {
      _messages.add(tempMessage);
      _messageController.clear();
      _lastTypingSent = null;
    });
    _scrollToBottom();

    final response = await _api.sendMessage(widget.chatId, text);

    if (response.success && response.data['message'] != null) {
      final realMessage = Message.fromJson(response.data['message']);
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = realMessage;
        } else {
          _messages.add(realMessage);
        }
      });
    } else {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = Message(
            id: tempMessage.id,
            senderId: tempMessage.senderId,
            type: tempMessage.type,
            content: tempMessage.content,
            status: 'failed',
            createdAt: tempMessage.createdAt,
          );
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendTypingStatus() {
    if (_isPending || _isSending) return;
    
    final now = DateTime.now();
    // Throttle typing updates to once every 5 seconds
    if (_lastTypingSent == null || now.difference(_lastTypingSent!).inSeconds > 5) {
      _lastTypingSent = now;
      _api.setTypingStatus(widget.chatId);
    }
  }

  void _sendRecordingStatus() {
    if (_isPending || !_isRecording) return;
    
    final now = DateTime.now();
    if (_lastRecordingSent == null || now.difference(_lastRecordingSent!).inSeconds > 5) {
      _lastRecordingSent = now;
      _api.setRecordingStatus(widget.chatId);
    }
  }

  // Voice Recording Methods
  Future<void> _startRecording() async {
    final started = await _voiceService.startRecording();
    if (started) {
      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });
      }
      
      _sendRecordingStatus(); // Send immediately

      // Start duration timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _recordingDuration++;
            if (_recordingDuration % 5 == 0) {
              _sendRecordingStatus();
            }
          });
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start recording. Please check microphone permission.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _stopAndSendVoice() async {
    _recordingTimer?.cancel();
    
    if (!_isRecording) return;
    
    final result = await _voiceService.stopRecording();
    
    setState(() => _isRecording = false);
    
    if (result == null || result.file == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save recording'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    
    // Don't send if recording is too short (less than 1 second)
    if (result.duration < 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording too short'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tempMessage = Message.optimistic(
      senderId: auth.user?.id ?? 0,
      type: 'voice',
      voiceDuration: result.duration,
    );

    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();
    
    final response = await _api.sendVoiceMessage(
      widget.chatId,
      result.file!,
      result.duration,
    );
    
    if (response.success && response.data['message'] != null) {
      try {
        debugPrint('📤 Voice message API response: ${response.data['message']}');
        final realMessage = Message.fromJson(response.data['message']);
        debugPrint('📤 Parsed voice message - voiceUrl: ${realMessage.voiceUrl}');
        setState(() {
          final index = _messages.indexWhere((m) => m.id == tempMessage.id);
          if (index != -1) {
            _messages[index] = realMessage;
          } else {
            _messages.add(realMessage);
          }
        });
      } catch (e) {
        debugPrint('📤 Error parsing voice message: $e');
      }
    } else {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = Message(
            id: tempMessage.id,
            senderId: tempMessage.senderId,
            type: tempMessage.type,
            voiceDuration: tempMessage.voiceDuration,
            status: 'failed',
            createdAt: tempMessage.createdAt,
          );
        }
      });
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _voiceService.cancelRecording();
    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
    });
  }

  String _formatRecordingDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _endChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Chat?'),
        content: const Text('Are you sure you want to end this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await _api.endChat(widget.chatId);

      if (response.success) {
        _showChatEndedDialog(summary: response.data['summary']);
      }
    }
  }

  void _showChatEndedDialog({Map<String, dynamic>? summary}) {
    _refreshTimer?.cancel();
    _billingTimer?.cancel();
    
    if (!mounted) return;
    
    // Store navigator before showing dialog
    final navigator = Navigator.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chat Ended'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.success),
            const SizedBox(height: AppSpacing.md),
            if (summary != null) ...[
              Text('Duration: ${summary['total_minutes'] ?? 0} minutes'),
              Text('Coins Spent: ${summary['coins_spent'] ?? 0}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              debugPrint('📞 Chat ended - navigating to home');
              
              // Try global key first, fallback to stored navigator
              final navState = navigatorKey.currentState;
              if (navState != null) {
                debugPrint('📞 Using global navigatorKey to reset app to Splash');
                navState.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              } else {
                debugPrint('📞 Global key null, using stored navigator to reset app to Splash');
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // If chat is pending, allow back without confirmation
    if (_isPending) return true;
    
    // Ask for confirmation to end chat
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Chat?'),
        content: const Text('Are you sure you want to end this chat session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Chat', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // End the chat
      await _api.endChat(widget.chatId);
      return true; // Allow navigation
    }
    
    return false; // Don't navigate
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isMale = auth.isMale;

    return PopScope(
      canPop: false, // Intercept back button
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent, // Make Scaffold transparent so wallpaper shows through
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.backgroundSecondary,
              backgroundImage: AuthProvider.getAvatarImage(widget.partnerAvatar),
              child: widget.partnerAvatar == null
                  ? Text(
                      widget.partnerName[0].toUpperCase(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.partnerName, style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                Text(
                  _isPartnerRecording
                      ? 'recording audio...'
                      : (_isPartnerTyping 
                          ? 'typing...' 
                          : (_isPending ? 'Waiting...' : '$_chatMinutes min')),
                  style: AppTextStyles.caption.copyWith(
                    color: (_isPartnerTyping || _isPartnerRecording) ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: (_isPartnerTyping || _isPartnerRecording) ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!_isPending && isMale)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CoinPurchaseScreen()),
                  ).then((_) {
                    Provider.of<AuthProvider>(context, listen: false).refreshProfile().then((_) {
                      _syncRemainingTime();
                    });
                  });
                },
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.add, size: 16, color: Colors.amber),
                      SizedBox(width: 2),
                      Icon(Icons.monetization_on_rounded, size: 18, color: Colors.amber),
                    ],
                  ),
                ),
              ),
            ),
          if (!_isPending)
            TextButton(
              onPressed: _endChat,
              child: const Text('End', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF3F2F7), // Light background
          image: DecorationImage(
            image: AssetImage('assets/images/chat_wallpaper.png'),
            repeat: ImageRepeat.repeat,
            opacity: 0.4, // Increased opacity for better visibility
          ),
        ),
        child: _isPending ? _buildPendingView() : _buildChatView(isMale),
      ),
    ),
  );
}

  Widget _buildPendingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Waiting for response...',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your request has been sent',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            text: 'Cancel Request',
            isOutlined: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildChatView(bool isMale) {
    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.user?.id ?? 0;

    return Column(
      children: [
        // Chat Stats Banner
        if (true) // Show for both male and female now
          Container(
            margin: const EdgeInsets.only(bottom: 1),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Icon(
                      isMale ? Icons.monetization_on_rounded : Icons.account_balance_wallet_rounded,
                      size: 16, 
                      color: Colors.amber
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      isMale 
                        ? '${auth.user?.coinBalance ?? 0}'
                        : '₹${auth.user?.earningBalance?.toStringAsFixed(2) ?? "0.00"}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 14,
                  color: Colors.grey.withOpacity(0.2),
                ),
                Row(
                  children: [
                    const Icon(Icons.timer_rounded,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _formatHHMMSS(_remainingSeconds),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Messages List
        Expanded(
          child: RepaintBoundary(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message.senderId == userId;
                return _MessageBubble(
                  key: ValueKey(message.id),
                  message: message, 
                  isMe: isMe
                );
              },
            ),
          ),
        ),

        // Input
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: _isRecording ? _buildRecordingUI() : _buildInputUI(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Cancel button
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.error),
            onPressed: _cancelRecording,
          ),
          
          // Recording indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          
          // Duration
          Expanded(
            child: Text(
              'Recording... ${_formatRecordingDuration(_recordingDuration)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Send button
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : _stopAndSendVoice,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputUI() {
    final hasText = _messageController.text.trim().isNotEmpty;
    
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: 5,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (hasText) _sendMessage();
              },
              onChanged: (_) {
                setState(() {}); // Rebuild to update button
                if (_messageController.text.trim().isNotEmpty) {
                  _sendTypingStatus();
                }
              },
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // Action Button (Send or Record)
        GestureDetector(
          onLongPressStart: hasText ? null : (_) => _startRecording(),
          onLongPressEnd: hasText ? null : (_) => _stopAndSendVoice(),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                hasText ? Icons.send : Icons.mic,
                color: Colors.white,
              ),
              onPressed: () {
                if (hasText) {
                  _sendMessage();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hold to record voice message'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Message Bubble Widget
class _MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  final VoiceService _voiceService = VoiceService.instance;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    // Listen to playback state changes
    _voiceService.playbackStateStream.listen((isPlaying) {
      if (mounted && widget.message.voiceUrl != null) {
        final isThisMessage = _voiceService.currentPlayingUrl == widget.message.voiceUrl;
        setState(() => _isPlaying = isPlaying && isThisMessage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: AppSpacing.xs,
          bottom: AppSpacing.xs,
          left: widget.isMe ? 60 : 0,
          right: widget.isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: widget.isMe ? AppColors.sentMessage : AppColors.receivedMessage,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.md),
            topRight: const Radius.circular(AppRadius.md),
            bottomLeft: Radius.circular(widget.isMe ? AppRadius.md : 4),
            bottomRight: Radius.circular(widget.isMe ? 4 : AppRadius.md),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.message.isVoice ? _buildVoiceContent() : _buildTextContent(),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.message.isFailed)
                  const Icon(Icons.error_outline, size: 12, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  _formatTime(widget.message.createdAt),
                  style: AppTextStyles.caption.copyWith(
                    color: widget.isMe ? Colors.white70 : AppColors.textLight,
                    fontSize: 10,
                  ),
                ),
                if (widget.isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    widget.message.isSending 
                        ? Icons.access_time 
                        : (widget.message.isFailed ? Icons.error_outline : Icons.done_all),
                    size: 12,
                    color: widget.message.isSending 
                        ? Colors.white54 
                        : (widget.message.isFailed ? AppColors.error : Colors.white70),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    return Text(
      widget.message.content ?? '',
      style: AppTextStyles.bodyMedium.copyWith(
        color: widget.isMe ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildVoiceContent() {
    final duration = widget.message.voiceDuration ?? 0;
    final durationText = _formatDuration(duration);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button
        GestureDetector(
          onTap: _togglePlayback,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.isMe ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: widget.isMe ? Colors.white : AppColors.primary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        
        // Waveform visualization (simplified)
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              12,
              (index) => Container(
                width: 3,
                height: _isPlaying ? (8.0 + (index % 4) * 4) : 8,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: widget.isMe 
                      ? Colors.white.withOpacity(_isPlaying ? 0.8 : 0.4) 
                      : AppColors.primary.withOpacity(_isPlaying ? 0.8 : 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        
        // Duration
        Text(
          durationText,
          style: AppTextStyles.caption.copyWith(
            color: widget.isMe ? Colors.white70 : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _togglePlayback() {
    debugPrint('🔊 Toggle playback - voiceUrl: ${widget.message.voiceUrl}');
    debugPrint('🔊 Message type: ${widget.message.type}, isVoice: ${widget.message.isVoice}');
    if (widget.message.voiceUrl != null) {
      _voiceService.togglePlayback(widget.message.voiceUrl!);
    } else {
      debugPrint('🔊 ERROR: voiceUrl is null! Cannot play.');
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
