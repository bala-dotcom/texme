import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/widgets.dart';
import '../home/home_screen.dart';
import 'voice_verification_screen.dart';

/// Registration Screen - Simplified
/// Male: No fields required (auto-generated name)
/// Female: Only avatar selection (no photo upload, no name)
class RegistrationScreen extends StatefulWidget {
  final String userType;

  const RegistrationScreen({
    super.key,
    required this.userType,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();

  // Predefined avatars for female users
  final List<String> _avatarOptions = [
    'https://api.dicebear.com/7.x/avataaars/png?seed=1',
    'https://api.dicebear.com/7.x/avataaars/png?seed=2',
    'https://api.dicebear.com/7.x/avataaars/png?seed=3',
    'https://api.dicebear.com/7.x/avataaars/png?seed=4',
    'https://api.dicebear.com/7.x/avataaars/png?seed=5',
    'https://api.dicebear.com/7.x/avataaars/png?seed=6',
    'https://api.dicebear.com/7.x/avataaars/png?seed=7',
    'https://api.dicebear.com/7.x/avataaars/png?seed=8',
  ];
  
  int _selectedAvatarIndex = 0;

  bool get isFemale => widget.userType == 'female';

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (isFemale && !_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.register(
      userType: widget.userType,
      name: null, // Auto-generated on backend
      age: null,
      bio: isFemale ? _bioController.text.trim() : null,
      avatarUrl: isFemale ? _avatarOptions[_selectedAvatarIndex] : null,
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
          isFemale ? 'Choose Avatar' : 'Complete Setup',
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isFemale) ...[
                      // Avatar Selection for Female
                      Text(
                        'Select Your Avatar',
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
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
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 35,
                                backgroundColor: AppColors.backgroundSecondary,
                                backgroundImage: NetworkImage(_avatarOptions[index]),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Bio (optional for females)
                      CustomTextField(
                        label: 'Bio (Optional)',
                        hint: 'Tell something about yourself...',
                        controller: _bioController,
                        maxLines: 3,
                        maxLength: 200,
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
                                'Your profile will be reviewed by admin before activation.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Male - Simple welcome message
                      const SizedBox(height: 60),
                      Icon(
                        Icons.check_circle,
                        size: 100,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Welcome!',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Your account is ready to use.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Register Button
                    PrimaryButton(
                      text: 'Continue',
                      onPressed: () {
                        if (isFemale) {
                          if (!_formKey.currentState!.validate()) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VoiceVerificationScreen(
                                userType: widget.userType,
                                bio: _bioController.text.trim(),
                                avatarUrl: _avatarOptions[_selectedAvatarIndex],
                              ),
                            ),
                          );
                        } else {
                          _register();
                        }
                      },
                      isLoading: auth.isLoading,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
