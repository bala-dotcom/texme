import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import 'chat_screen.dart';

/// Connecting Screen - Shown to male user while waiting for female to accept
class ConnectingScreen extends StatefulWidget {
  final FemaleUser user;

  const ConnectingScreen({super.key, required this.user});

  @override
  State<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends State<ConnectingScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService.instance;
  
  Timer? _pollTimer;
  Timer? _timeoutTimer;
  int? _chatId;
  bool _isConnecting = true;
  String _status = 'Connecting...';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _sendChatRequest();
  }

  void _setupAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _sendChatRequest() async {
    final response = await _api.sendChatRequest(widget.user.id);

    if (!mounted) return;

    if (response.success) {
      _chatId = response.data['chat_id'];
      _startPolling();
      _startTimeout();
    } else {
      // Check if the error is "already in a chat"
      final message = response.message ?? 'Failed to connect';
      
      if (message.contains('already in')) {
        setState(() {
          _status = 'Reconnecting to your active chat...';
        });
        // Try to get the active chat and navigate there
        final activeResponse = await _api.getActiveChat();
        if (activeResponse.success && activeResponse.data['has_active_chat'] == true) {
          final chatId = activeResponse.data['chat_id'];
          final partnerName = activeResponse.data['partner']?['name'] ?? 'User';
          final partnerAvatar = activeResponse.data['partner']?['avatar'];
          
          _stopTimers();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: int.tryParse(chatId.toString()) ?? 0,
                  partnerName: partnerName,
                  partnerAvatar: partnerAvatar,
                  isPending: false,
                  ratePerMinute: widget.user.ratePerMinute,
                ),
              ),
            );
          }
          return;
        }
      }
      
      setState(() {
        _isConnecting = false;
        _status = message;
      });
      
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }

  void _startPolling() {
    // Poll every 1 second for faster response when female accepts/declines
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_chatId == null) return;

      final response = await _api.getChatStatus(_chatId!);
      
      // Debug logging
      debugPrint('🔍 Poll response: success=${response.success}, data=${response.data}');

      if (!mounted) return;

      if (response.success) {
        final status = response.data['status'];
        debugPrint('🔍 Status from polling: $status');
        
        if (status == 'active') {
          // Female accepted! Go to chat
          debugPrint('✅ Chat is ACTIVE! Navigating to chat room...');
          _stopTimers();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: _chatId!,
              partnerName: widget.user.name,
              partnerAvatar: widget.user.avatar,
              isPending: false,
              ratePerMinute: widget.user.ratePerMinute,
            ),
          ),
          );
        } else if (status == 'ended') {
          // Female rejected or request cancelled
          debugPrint('❌ Chat was DECLINED/ENDED');
          _stopTimers();
          setState(() {
            _isConnecting = false;
            _status = 'User declined the request';
          });
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.pop(context);
        }
      }
    });
  }

  void _startTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      
      setState(() {
        _isConnecting = false;
        _status = 'User is not available';
      });
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    });
  }

  void _stopTimers() {
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
    _pollTimer = null;
    _timeoutTimer = null;
  }

  void _cancelRequest() async {
    _stopTimers();
    
    if (_chatId != null) {
      await _api.cancelChatRequest(_chatId!);
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _stopTimers();
    _pulseController.dispose();
    super.dispose();
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
            colors: [
              Color(0xFF6366F1), // Indigo
              Color(0xFF8B5CF6), // Purple
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with cancel
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _cancelRequest,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // User Avatar with pulse
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isConnecting ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: widget.user.avatar != null
                            ? Image.network(
                                widget.user.avatar!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                              )
                            : _buildAvatarPlaceholder(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // User Name
              Text(
                widget.user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Status
              Text(
                _status,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Rate info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '₹${widget.user.ratePerMinute.toStringAsFixed(0)}/min',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const Spacer(),

              // Loading indicator or status icon
              if (_isConnecting)
                const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Icon(
                    _status.contains('declined') 
                        ? Icons.close 
                        : Icons.error_outline,
                    color: Colors.white,
                    size: 50,
                  ),
                ),

              // Cancel Button
              if (_isConnecting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: TextButton(
                    onPressed: _cancelRequest,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.3),
      child: Center(
        child: Text(
          widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 60,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
