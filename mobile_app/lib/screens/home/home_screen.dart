import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import 'male_home_screen.dart';
import 'female_home_screen.dart';
import '../auth/phone_login_screen.dart';
import '../auth/pending_verification_screen.dart';

/// Home Screen - Routes to Male or Female home based on user type
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    // If not logged in, go to login
    if (!auth.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
      );
      return;
    }

    // If female and not verified, go to pending
    if (auth.user?.isFemale == true && auth.user?.voiceStatus != 'verified') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PendingVerificationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (!auth.isLoggedIn) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          );
        }

        // Route based on user type
        if (auth.isMale) {
          return const MaleHomeScreen();
        } else {
          return const FemaleHomeScreen();
        }
      },
    );
  }
}
