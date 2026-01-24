import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/widgets.dart';
import '../home/home_screen.dart';

/// Male Avatar Selection Screen
/// Allows male users to select an avatar during registration
class MaleAvatarSelectionScreen extends StatefulWidget {
  const MaleAvatarSelectionScreen({super.key});

  @override
  State<MaleAvatarSelectionScreen> createState() => _MaleAvatarSelectionScreenState();
}

class _MaleAvatarSelectionScreenState extends State<MaleAvatarSelectionScreen> {
  // Male avatar options - you will add avatar images to assets/images/avatars/male/
  final List<String> _avatarOptions = [
    'assets/images/avatars/male/avatar_m1.png',
    'assets/images/avatars/male/avatar_m2.png',
    'assets/images/avatars/male/avatar_m3.png',
    'assets/images/avatars/male/avatar_m4.png',
    'assets/images/avatars/male/avatar_m5.png',
    'assets/images/avatars/male/avatar_m6.png',
    'assets/images/avatars/male/avatar_m7.png',
    'assets/images/avatars/male/avatar_m8.png',
  ];

  int _selectedAvatarIndex = 0;

  Future<void> _register() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.register(
      userType: 'male',
      name: null, // Auto-generated on backend
      age: null,
      bio: null,
      avatarUrl: _avatarOptions[_selectedAvatarIndex],
    );

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose Avatar',
          style: AppTextStyles.h4,
        ),
        centerTitle: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          return LoadingOverlay(
            isLoading: auth.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Selected Avatar Preview
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        _avatarOptions[_selectedAvatarIndex],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.backgroundSecondary,
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Title
                  Text(
                    'Select Your Avatar',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Choose an avatar that represents you',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Avatar Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _avatarOptions.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedAvatarIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatarIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: AppColors.backgroundSecondary,
                            child: ClipOval(
                              child: Image.asset(
                                _avatarOptions[index],
                                fit: BoxFit.cover,
                                width: 70,
                                height: 70,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person,
                                  size: 35,
                                  color: isSelected ? AppColors.primary : AppColors.textLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Info box
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'You can change your avatar later in settings.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Continue Button
                  PrimaryButton(
                    text: 'Continue',
                    onPressed: _register,
                    isLoading: auth.isLoading,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
