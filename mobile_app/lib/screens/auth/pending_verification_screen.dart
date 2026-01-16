import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/widgets.dart';
import '../home/home_screen.dart';

class PendingVerificationScreen extends StatefulWidget {
  const PendingVerificationScreen({super.key});

  @override
  State<PendingVerificationScreen> createState() => _PendingVerificationScreenState();
}

class _PendingVerificationScreenState extends State<PendingVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // Initial check
    _checkStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshProfile();
    
    if (mounted && authProvider.user?.voiceStatus == 'verified') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted && authProvider.user?.voiceStatus == 'rejected') {
       // If rejected, maybe they need to record again? 
       // For now just show the status
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isRejected = user?.voiceStatus == 'rejected';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rotating hourglass
              RotationTransition(
                turns: _controller,
                child: Icon(
                  isRejected ? Icons.error_outline : Icons.hourglass_empty_rounded,
                  size: 80,
                  color: isRejected ? AppColors.error : AppColors.primary,
                ),
              ),
              const SizedBox(height: 40),
              
              Text(
                isRejected ? 'Verification Rejected' : 'Verification Pending',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Text(
                isRejected 
                  ? 'Your voice verification was rejected. Please contact support or try again later.'
                  : 'Your voice sample is being reviewed by our team. This usually takes less than 24 hours.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
