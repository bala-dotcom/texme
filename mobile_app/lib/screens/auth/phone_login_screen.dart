import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/widgets.dart';
import '../profile/terms_of_service_screen.dart';
import '../profile/privacy_policy_screen.dart';
import 'gender_selection_screen.dart';
import '../home/home_screen.dart';
import 'otp_screen.dart';
import 'pending_verification_screen.dart';

/// Phone Login Screen
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValid = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _validatePhone(String value) {
    setState(() {
      _isValid = RegExp(r'^[6-9]\d{9}$').hasMatch(value);
    });
  }

  Future<void> _sendOtp() async {
    if (!_isValid) return;

    final phone = _phoneController.text.trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.sendOtp(phone);

    if (!mounted) return;

    if (result) {
      // OTP sent successfully, navigate to verification screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OtpScreen()),
      );
    } else {
      // Error sending OTP
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to send OTP'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleSuccess() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isNewUser) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GenderSelectionScreen()),
      );
    } else {
      final user = authProvider.user;
      if (user?.isFemale == true && user?.voiceStatus == 'pending') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PendingVerificationScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<AuthProvider>(
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
                      const SizedBox(height: 60),

                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // App Name
                      Text(
                        'Texme',
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Tagline
                      Text(
                        'Connect & Chat',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Welcome Text
                      Text(
                        'Welcome!',
                        style: AppTextStyles.h2,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Enter your phone number to continue',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Phone Input
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: _isValid
                                ? AppColors.primary
                                : AppColors.border,
                            width: _isValid ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Country Code
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '🇮🇳',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '+91',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Phone Field
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                onChanged: _validatePhone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontSize: 18,
                                  letterSpacing: 1,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Enter phone number',
                                  border: InputBorder.none,
                                  counterText: '',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.md,
                                  ),
                                ),
                              ),
                            ),

                            // Check Icon
                            if (_isValid)
                              const Padding(
                                padding: EdgeInsets.only(right: AppSpacing.md),
                                child: Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Continue Button
                      PrimaryButton(
                        text: 'Continue',
                        onPressed: _isValid ? _sendOtp : null,
                        isLoading: auth.isLoading,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Terms
                      Text(
                        'By continuing, you agree to our',
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                              );
                            },
                            child: Text(
                              'Terms of Service',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            ' & ',
                            style: AppTextStyles.bodySmall,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                              );
                            },
                            child: Text(
                              'Privacy Policy',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
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
          },
        ),
      ),
    );
  }
}
