import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../config/theme.dart';
import '../../models/chat.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../services/fcm_service.dart';
import 'chat_screen.dart';

/// Incoming Call Screen - Shown to female when male requests chat
class IncomingCallScreen extends StatefulWidget {
  final ChatRequest request;
  final VoidCallback? onDismiss;

  const IncomingCallScreen({
    super.key,
    required this.request,
    this.onDismiss,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isProcessing = false;
  Timer? _timeoutTimer;
  Timer? _pollTimer;
  int _remainingSeconds = 30;

  // Ripple animation controllers
  late AnimationController _rippleController1;
  late AnimationController _rippleController2;
  late AnimationController _rippleController3;
  late Animation<double> _rippleAnimation1;
  late Animation<double> _rippleAnimation2;
  late Animation<double> _rippleAnimation3;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startTimeout();
    _startPollingForCancellation();
    _playRingtone();
  }

  void _setupAnimation() {
    // Create staggered ripple animations
    _rippleController1 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _rippleController2 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _rippleController3 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rippleAnimation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController1, curve: Curves.easeOut),
    );
    
    _rippleAnimation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController2, curve: Curves.easeOut),
    );
    
    _rippleAnimation3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController3, curve: Curves.easeOut),
    );

    // Start staggered animations
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _rippleController2.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _rippleController3.repeat();
    });
  }

  void _startTimeout() {
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _dismiss();
      }
    });
  }

  /// Poll every 1 second to check if male has cancelled the request
  void _startPollingForCancellation() {
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_isProcessing) return;
      
      final response = await _api.getChatStatus(widget.request.chatId);
      
      if (!mounted) return;
      
      if (response.success) {
        final status = response.data['status'];
        debugPrint('📞 Incoming call poll: status=$status');
        
        if (status == 'ended') {
          // Male cancelled the request
          debugPrint('📞 Male cancelled the request');
          _pollTimer?.cancel();
          _timeoutTimer?.cancel();
          _stopRingtone();
          
          // Show message and dismiss
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Request was cancelled'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
            _dismiss();
          }
        }
      }
    });
  }

  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(
        UrlSource('https://www.soundjay.com/phone/phone-calling-1.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('Error playing ringtone: $e');
    }
  }

  Future<void> _stopRingtone() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.dispose();
    } catch (e) {
      debugPrint('Error stopping ringtone: $e');
    }
  }

  Future<void> _acceptRequest() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    _timeoutTimer?.cancel();
    _pollTimer?.cancel();
    _stopRingtone();
    
    debugPrint('📞 In-app accept: accepting chat ${widget.request.chatId}');
    
    // Cancel notification and mark as handled
    NotificationService.instance.cancelIncomingCallNotification(widget.request.chatId);
    FcmService.instance.markChatHandled(widget.request.chatId);

    final response = await _api.acceptChat(widget.request.chatId);
    debugPrint('📞 In-app accept API result: success=${response.success}, message=${response.message}');

    if (!mounted) {
      debugPrint('📞 In-app accept: widget not mounted after API call');
      return;
    }

    if (response.success) {
      debugPrint('📞 In-app accept: navigating to ChatScreen');
      // Use pushAndRemoveUntil to clear stack and go to chat
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: widget.request.chatId,
            partnerName: widget.request.maleName,
            partnerAvatar: widget.request.maleAvatar,
            isPending: false,
          ),
        ),
        (route) => route.isFirst, // Keep only the first route (HomeScreen)
      );
    } else {
      debugPrint('📞 In-app accept: failed - ${response.message}');
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Failed to accept'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _declineRequest() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    _timeoutTimer?.cancel();
    _pollTimer?.cancel();
    _stopRingtone();
    
    // Cancel notification and mark as handled
    NotificationService.instance.cancelIncomingCallNotification(widget.request.chatId);
    FcmService.instance.markChatHandled(widget.request.chatId);

    await _api.declineChat(widget.request.chatId);
    _dismiss();
  }

  void _dismiss() {
    if (mounted) {
      Navigator.pop(context);
      widget.onDismiss?.call();
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _pollTimer?.cancel();
    _rippleController1.dispose();
    _rippleController2.dispose();
    _rippleController3.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Build a single ripple circle
  Widget _buildRipple(Animation<double> animation, double maxSize) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final size = 60 + (maxSize - 60) * animation.value;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15 * (1 - animation.value)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2DD4BF), Color(0xFF14B8A6)], // Teal gradient
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Header
              Text(
                'INCOMING CHAT',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              
              // Timer
              Text(
                '0:${_remainingSeconds.toString().padLeft(2, '0')}',
                style: AppTextStyles.h4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              // Avatar with glowing ripple
              SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildRipple(_rippleAnimation1, 280),
                    _buildRipple(_rippleAnimation2, 220),
                    _buildRipple(_rippleAnimation3, 160),
                    
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: widget.request.maleAvatar != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(widget.request.maleAvatar!),
                            )
                          : const Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // User Info
              Text(
                widget.request.maleName,
                style: AppTextStyles.h2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'wants to chat with you',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Earning Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Earn ${widget.request.potentialEarningFormatted}',
                      style: AppTextStyles.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Action Buttons
              if (!_isProcessing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Decline
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _declineRequest,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444), // Red
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 32),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Decline', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                        ],
                      ),
                      
                      // Accept
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _acceptRequest,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: Colors.white, 
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.check, color: Color(0xFF10B981), size: 36), // Green check
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Accept', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
