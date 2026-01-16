import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../chat/chat_screen.dart';
import '../chat/connecting_screen.dart';

/// Chat History model
class ChatHistory {
  final int chatId;
  final int partnerId;
  final String partnerName;
  final String? partnerAvatar;
  final DateTime? lastChatTime;
  final int totalMinutes;
  final int coinsSpent;
  final double femaleEarnings;
  final String status;
  final bool isOnline;

  ChatHistory({
    required this.chatId,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatar,
    this.lastChatTime,
    required this.totalMinutes,
    required this.coinsSpent,
    required this.femaleEarnings,
    required this.status,
    this.isOnline = false,
  });

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    // Handle female_earnings which can be String or number
    double earnings = 0.0;
    if (json['female_earnings'] != null) {
      if (json['female_earnings'] is String) {
        earnings = double.tryParse(json['female_earnings']) ?? 0.0;
      } else {
        earnings = (json['female_earnings'] as num).toDouble();
      }
    }
    
    return ChatHistory(
      chatId: json['chat_id'] ?? 0,
      partnerId: json['partner_id'] ?? 0,
      partnerName: json['partner_name'] ?? 'Unknown',
      partnerAvatar: json['partner_avatar'],
      lastChatTime: json['ended_at'] != null 
          ? DateTime.tryParse(json['ended_at']) 
          : null,
      totalMinutes: json['total_minutes'] ?? 0,
      coinsSpent: json['coins_spent'] ?? 0,
      femaleEarnings: earnings,
      status: json['status'] ?? 'ended',
      isOnline: json['is_online'] ?? false,
    );
  }
}

/// Chats History Screen - Shows list of past chats
class ChatsHistoryScreen extends StatefulWidget {
  const ChatsHistoryScreen({super.key});

  @override
  State<ChatsHistoryScreen> createState() => _ChatsHistoryScreenState();
}

class _ChatsHistoryScreenState extends State<ChatsHistoryScreen> {
  final ApiService _api = ApiService.instance;
  List<ChatHistory> _chats = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    setState(() => _isLoading = true);

    final response = await _api.getChatHistory();
    
    debugPrint('🔍 Chat History Response: success=${response.success}');
    debugPrint('🔍 Response data: ${response.data}');
    debugPrint('🔍 Response message: ${response.message}');

    if (!mounted) return;

    if (response.success && response.data != null && response.data['chats'] != null) {
      final List chats = response.data['chats'];
      debugPrint('🔍 Found ${chats.length} chats');
      setState(() {
        _chats = chats.map((c) => ChatHistory.fromJson(c)).toList();
      });
    } else {
      debugPrint('❌ Failed to load chat history');
    }

    setState(() => _isLoading = false);
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  void _startChatWithPartner(ChatHistory chat) {
    // Create a FemaleUser from the chat history data to use with ConnectingScreen
    final femaleUser = FemaleUser(
      id: chat.partnerId,
      name: chat.partnerName,
      avatar: chat.partnerAvatar,
      status: 'online', // Assume online for now
      isAvailable: true,
      ratePerMinute: 10.0, // Default rate
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConnectingScreen(user: femaleUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isMale = auth.isMale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Text(
                'Recent Chats',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadChatHistory,
                ),
            ],
          ),
        ),

        // Chat List
        Expanded(
          child: _isLoading && _chats.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _chats.isEmpty
                  ? _buildEmptyState()
                  : _buildChatList(isMale),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No chat history yet',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start chatting to see your conversations here',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(bool isMale) {
    return RefreshIndicator(
      onRefresh: _loadChatHistory,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return _ChatHistoryCard(
            chat: chat,
            isMale: isMale,
            timeAgo: _formatTime(chat.lastChatTime),
            onTap: () {
              // Show chat details or allow reconnect
              _showChatDetails(chat);
            },
            onStartChat: isMale ? () => _startChatWithPartner(chat) : null,
          );
        },
      ),
    );
  }

  void _showChatDetails(ChatHistory chat) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isMale = auth.isMale;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: chat.partnerAvatar != null
                  ? NetworkImage(chat.partnerAvatar!)
                  : null,
              child: chat.partnerAvatar == null
                  ? Text(
                      chat.partnerName[0].toUpperCase(),
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            
            Text(
              chat.partnerName,
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatChip(
                  icon: Icons.timer_outlined,
                  label: '${chat.totalMinutes} min',
                ),
                const SizedBox(width: AppSpacing.md),
                _StatChip(
                  icon: isMale ? Icons.monetization_on_outlined : Icons.account_balance_wallet_outlined,
                  label: isMale 
                      ? '${chat.coinsSpent} coins'
                      : '₹${chat.femaleEarnings.toStringAsFixed(0)}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            Text(
              'Last chat: ${_formatTime(chat.lastChatTime)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Buttons
            if (isMale) ...[ 
              // Start Chat button for male users
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                    _startChatWithPartner(chat);
                  },
                  icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
                  label: const Text(
                    'Start Chat',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            // Close button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: AppColors.border),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat History Card Widget
class _ChatHistoryCard extends StatelessWidget {
  final ChatHistory chat;
  final bool isMale;
  final String timeAgo;
  final VoidCallback onTap;
  final VoidCallback? onStartChat;

  const _ChatHistoryCard({
    required this.chat,
    required this.isMale,
    required this.timeAgo,
    required this.onTap,
    this.onStartChat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: chat.partnerAvatar != null
                        ? NetworkImage(chat.partnerAvatar!)
                        : null,
                    child: chat.partnerAvatar == null
                        ? Text(
                            chat.partnerName[0].toUpperCase(),
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  // Online indicator dot
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: chat.isOnline ? AppColors.success : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.partnerName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${chat.totalMinutes} min',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        // Only show earnings for female users
                        if (!isMale) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '₹${chat.femaleEarnings.toStringAsFixed(0)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Start Chat button for males (centered vertically)
              if (isMale && onStartChat != null)
                GestureDetector(
                  onTap: chat.isOnline ? onStartChat : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: chat.isOnline ? AppColors.primary : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Start Chat',
                      style: TextStyle(
                        color: chat.isOnline ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              // Time and status for females
              else if (!isMale)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeAgo,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: chat.status == 'active' 
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.textLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        chat.status == 'active' ? 'Active' : 'Ended',
                        style: AppTextStyles.caption.copyWith(
                          color: chat.status == 'active' 
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stat Chip Widget
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
