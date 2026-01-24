import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/widgets.dart';
import '../home/home_screen.dart';
import 'registration_screen.dart';
import 'male_avatar_selection_screen.dart';

/// Gender Selection Screen (Step 2 after phone verification)
class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  bool _isLoading = false;

  void _goToMaleAvatarSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MaleAvatarSelectionScreen(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Title
                Text(
                  'Who are you?',
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Select your gender to continue',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 60),

                // Male Option - Go to avatar selection screen
                _GenderCard(
                  icon: Icons.male,
                  title: "I'm Male",
                  color: Colors.blue,
                  onTap: _goToMaleAvatarSelection,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Female Option - Go to registration screen
                _GenderCard(
                  icon: Icons.female,
                  title: "I'm Female",
                  color: Colors.pink,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegistrationScreen(userType: 'female'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gender Card Widget
class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _GenderCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: color,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Text
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.h3,
              ),
            ),

            // Arrow
            const Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
