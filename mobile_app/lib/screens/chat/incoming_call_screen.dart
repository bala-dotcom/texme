import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/chat.dart';
import '../../providers/auth_provider.dart';
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
  Timer? _dotTimer;
  int _remainingSeconds = 30;
  int _dotCount = 0;

  // Ripple animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startTimeout();
    _startPollingForCancellation();
    _startDotAnimation();
    _playRingtone();
  }

  void _setupAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startDotAnimation() {
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
      }
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
          _dotTimer?.cancel();
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
    _dotTimer?.cancel();
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
    _dotTimer?.cancel();
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
    _dotTimer?.cancel();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _buildAvatar(String? avatarUrl, String name, String label, bool isPulsing) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isPulsing && !_isProcessing ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF6C5CE7).withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(name),
                          )
                        : _buildPlaceholder(name),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String name) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentUser = auth.user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // "Connecting" text with animated dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Incoming Chat',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                // Animated dots
                Row(
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index <= _dotCount 
                            ? const Color(0xFF6C5CE7) 
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
              ],
            ),

            const Spacer(),

            // Top avatar (male user calling)
            _buildAvatar(
              widget.request.maleAvatar,
              widget.request.maleName,
              widget.request.maleName,
              true,
            ),

            const SizedBox(height: 40),

            // "[name] wants to chat with you" text
            Text(
              '${widget.request.maleName} wants to chat with you',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

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
                        Text('Decline', style: TextStyle(color: Colors.grey.shade600)),
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
                              color: Color(0xFF10B981), // Green
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 36),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Accept', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
