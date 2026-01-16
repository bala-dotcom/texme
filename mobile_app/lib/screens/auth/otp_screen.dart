import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/widgets.dart';
import 'gender_selection_screen.dart';
import '../home/home_screen.dart';
import 'pending_verification_screen.dart';

/// OTP Verification Screen
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isComplete = false;

  // Resend timer
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTimerTick);
  }

  void _onTimerTick(Timer timer) {
    // Immediately cancel if widget is disposed
    if (!mounted) {
      timer.cancel();
      _timer = null;
      return;
    }

    if (_resendSeconds > 0) {
      setState(() => _resendSeconds--);
    } else {
      timer.cancel();
      _timer = null;
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(_otpController.text);

    if (success && mounted) {
      if (authProvider.isNewUser) {
        // New user - go to gender selection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GenderSelectionScreen()),
        );
      } else {
        // Existing user
        final user = authProvider.user;
        if (user?.isFemale == true && user?.voiceStatus != 'verified') {
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
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Invalid OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      _otpController.clear();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(authProvider.phone!);

    if (success && mounted) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully'),
          backgroundColor: AppColors.success,
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
          onPressed: () {
            Provider.of<AuthProvider>(context, listen: false).resetAuthFlow();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            final maskedPhone = auth.phone != null
                ? '+91 ${auth.phone!.substring(0, 2)}XXXXXX${auth.phone!.substring(8)}'
                : '';

            return LoadingOverlay(
              isLoading: auth.isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sms_outlined,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Title
                    Text(
                      'Verify OTP',
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Subtitle
                    Text(
                      'Enter the 6-digit code sent to',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      maskedPhone,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // OTP Input
                    PinCodeTextField(
                      appContext: context,
                      length: 6,
                      controller: _otpController,
                      obscureText: false,
                      animationType: AnimationType.fade,
                      keyboardType: TextInputType.number,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        fieldHeight: 56,
                        fieldWidth: 48,
                        activeFillColor: AppColors.backgroundSecondary,
                        inactiveFillColor: AppColors.backgroundSecondary,
                        selectedFillColor: AppColors.backgroundSecondary,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.border,
                        selectedColor: AppColors.primary,
                      ),
                      animationDuration: const Duration(milliseconds: 200),
                      enableActiveFill: true,
                      onCompleted: (value) {
                        setState(() => _isComplete = true);
                        _verifyOtp();
                      },
                      onChanged: (value) {
                        setState(() => _isComplete = value.length == 6);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Verify Button
                    PrimaryButton(
                      text: 'Verify',
                      onPressed: _isComplete ? _verifyOtp : null,
                      isLoading: auth.isLoading,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Resend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: _resendSeconds == 0 ? _resendOtp : null,
                          child: Text(
                            _resendSeconds > 0
                                ? 'Resend in ${_resendSeconds}s'
                                : 'Resend',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: _resendSeconds > 0
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
