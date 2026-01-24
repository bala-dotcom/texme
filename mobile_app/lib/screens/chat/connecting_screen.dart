import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'chat_screen.dart';
import '../wallet/coin_purchase_screen.dart';

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
  int _dotCount = 0;
  Timer? _dotTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startDotAnimation();
    _sendChatRequest();
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
      
      if (message.contains('Not enough coins')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have not enough coins'),
              backgroundColor: AppColors.warning,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CoinPurchaseScreen()),
          );
        }
        return;
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
    _dotTimer?.cancel();
    _pollTimer = null;
    _timeoutTimer = null;
    _dotTimer = null;
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

  Widget _buildAvatar(String? avatarUrl, String name, String label, bool isPulsing) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isPulsing && _isConnecting ? _pulseAnimation.value : 1.0,
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
                        ? avatarUrl.startsWith('assets/')
                            ? Image.asset(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaceholder(name),
                              )
                            : Image.network(
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
    final dots = '.' * (_dotCount + 1);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _cancelRequest();
      },
      child: Scaffold(
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
                  'Connecting',
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

            // Top avatar (female user being called)
            _buildAvatar(
              widget.user.avatar,
              widget.user.name,
              widget.user.name,
              true,
            ),

            const SizedBox(height: 20),

            // Connecting line
            Container(
              width: 2,
              height: 80,
              color: Colors.grey.shade300,
            ),

            const SizedBox(height: 20),

            // Bottom avatar (current user - You)
            _buildAvatar(
              currentUser?.avatar,
              currentUser?.name ?? 'You',
              'You',
              false,
            ),

            const SizedBox(height: 40),

            // "Connecting to [name]" text
            Text(
              'Connecting to ${widget.user.name}',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            // Status text
            if (!_isConnecting)
              Text(
                _status,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),

            const Spacer(),

            // Cancel button
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: TextButton(
                onPressed: _cancelRequest,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade600,
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
}
