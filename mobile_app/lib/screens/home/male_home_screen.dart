import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/widgets.dart';
import '../chat/chat_screen.dart';
import '../chat/connecting_screen.dart';
import '../profile/profile_screen.dart';
import '../wallet/coin_purchase_screen.dart';
import 'chats_history_screen.dart';

/// Male Home Screen - Browse females, random connect, coin balance
class MaleHomeScreen extends StatefulWidget {
  const MaleHomeScreen({super.key});

  @override
  State<MaleHomeScreen> createState() => _MaleHomeScreenState();
}

class _MaleHomeScreenState extends State<MaleHomeScreen> {
  final ApiService _api = ApiService.instance;
  int _currentIndex = 0;
  Timer? _profileTimer;

  List<FemaleUser> _females = [];
  bool _isLoading = false;
  bool _isLoadingRandom = false;

  @override
  void initState() {
    super.initState();
    _loadFemales();
    _checkActiveChat(); // Check if user has an active chat
    
    // Periodically refresh profile for real-time coin balance
    _profileTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).refreshProfile();
      }
    });
  }

  @override
  void dispose() {
    _profileTimer?.cancel();
    super.dispose();
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
            ratePerMinute: chatData['partner']?['rate_per_minute'] != null 
                ? double.tryParse(chatData['partner']['rate_per_minute'].toString()) 
                : null,
          ),
        ),
      );
    }
  }

  Future<void> _loadFemales() async {
    setState(() => _isLoading = true);

    final response = await _api.getFemales();

    if (response.success && response.data['users'] != null) {
      final List users = response.data['users'];
      setState(() {
        _females = users.map((u) => FemaleUser.fromJson(u)).toList();
      });
    }

    setState(() => _isLoading = false);
  }

  void _randomConnect() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Random Connect is coming soon!'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _connectToUser(FemaleUser user) {
    // Navigate directly to connecting screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConnectingScreen(user: user),
      ),
    );
  }

  Future<void> _sendChatRequest(FemaleUser user) async {
    Navigator.pop(context); // Close bottom sheet

    final response = await _api.sendChatRequest(user.id);

    if (response.success) {
      // Navigate to waiting screen
      final chatId = response.data['chat_id'];
      if (mounted && chatId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: int.tryParse(chatId.toString()) ?? 0,
              partnerName: user.name,
              partnerAvatar: user.avatar,
              isPending: true,
              ratePerMinute: user.ratePerMinute,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to send request'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

              // Coin Balance - Tappable
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CoinPurchaseScreen()),
                  );
                  // Refresh balance when returning
                  if (mounted) {
                    Provider.of<AuthProvider>(context, listen: false).refreshProfile();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${user?.coinBalance ?? 0}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
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

        // Random Connect Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: InkWell(
            onTap: _randomConnect,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shuffle, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Random Connect',
                          style: AppTextStyles.h4.copyWith(color: Colors.white),
                        ),
                        Text(
                          'Connect with someone now!',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Users Grid
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                )
              : _females.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline,
                              size: 64, color: AppColors.textLight),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No users available',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFemales,
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _females.length,
                        itemBuilder: (context, index) {
                          final female = _females[index];
                          return _UserImageCard(
                            user: female,
                            onTap: () => _connectToUser(female),
                          );
                        },
                      ),
                    ),
        ),
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

/// User Preview Bottom Sheet
class _UserPreviewSheet extends StatelessWidget {
  final FemaleUser user;
  final VoidCallback onConnect;

  const _UserPreviewSheet({
    required this.user,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.backgroundSecondary,
            backgroundImage:
                user.avatar != null ? NetworkImage(user.avatar!) : null,
            child: user.avatar == null
                ? Text(
                    user.name[0].toUpperCase(),
                    style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // Name & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(user.name, style: AppTextStyles.h2),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: user.isAvailable ? AppColors.online : AppColors.busy,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          if (user.age != null)
            Text(
              '${user.age} years old',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),

          // Bio
          if (user.bio != null && user.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                user.bio!,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Rate
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  '₹${user.ratePerMinute.toStringAsFixed(0)}/min',
                  style: AppTextStyles.h4,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Connect Button
          PrimaryButton(
            text: user.isAvailable ? 'Start Chat' : 'User is Busy',
            icon: Icons.chat_bubble,
            onPressed: user.isAvailable ? onConnect : null,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// Beautiful Image Card for Users (Dating App Style)
class _UserImageCard extends StatelessWidget {
  final FemaleUser user;
  final VoidCallback onTap;

  const _UserImageCard({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // User Image or Placeholder
              if (user.avatar != null)
                Image.network(
                  user.avatar!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                )
              else
                _buildPlaceholder(),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Online Indicator
              if (user.isAvailable)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Online',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // User Info at Bottom
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name and Age
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Age Badge
                        if (user.age != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${user.age}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            user.location ?? 'India',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.primary.withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
