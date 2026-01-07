import 'package:flutter/material.dart';
import '../../config/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle('Privacy Policy for Texme'),
            _buildParagraph(
              'Texme ("we", "our", or "us") respects your privacy and is committed to protecting it. This Privacy Policy explains how we collect, use, and protect your information when you use the Texme mobile application ("App").',
            ),
            _buildParagraph(
              'Texme is a one-to-one messaging platform designed with user privacy as a priority.',
            ),
            const Divider(height: 32),

            _buildSectionTitle('1. Information We Collect'),
            _buildSubTitle('a. Information You Provide'),
            _buildParagraph(
              'We collect only the minimum information required to operate the app:',
            ),
            _buildBullet('Mobile Number – used for login and verification'),
            _buildBullet('OTP (One-Time Password) – used only for authentication'),
            _buildBullet('Gender Selection'),
            _buildSubTitle('For Female Users Only:'),
            _buildBullet('Age'),
            _buildBullet('Interests'),
            const SizedBox(height: 8),
            _buildNote('Note: Profile pictures are not required. Male users are not required to enter name, age, or interests.'),
            const Divider(height: 32),

            _buildSubTitle('b. Payment Information'),
            _buildBullet('Male users may purchase coins to chat.'),
            _buildBullet('Female users may earn money through chats.'),
            _buildParagraph(
              'All payments are processed through third-party payment gateways. Texme does not store your card, bank, or payment credentials.',
            ),
            const Divider(height: 32),

            _buildSectionTitle('2. How We Use Your Information'),
            _buildParagraph('We use collected information only to:'),
            _buildBullet('Verify user identity via OTP'),
            _buildBullet('Enable one-to-one messaging'),
            _buildBullet('Match users based on interests (female users)'),
            _buildBullet('Process coin purchases and payouts'),
            _buildBullet('Prevent fraud, abuse, or misuse of the app'),
            _buildBullet('Improve app performance and user experience'),
            const Divider(height: 32),

            _buildSectionTitle('3. Messages & Chat Privacy'),
            _buildBullet('Texme provides private one-to-one messaging'),
            _buildBullet('Messages are not shared with other users'),
            _buildBullet('We do not sell or publicly display chat content'),
            _buildBullet('Chat data may be temporarily stored for moderation, security, or legal compliance'),
            const Divider(height: 32),

            _buildSectionTitle('4. Data Sharing'),
            _buildParagraph('We do not sell, rent, or trade your personal data.'),
            _buildParagraph('We may share limited data only:'),
            _buildBullet('With payment providers (for transactions)'),
            _buildBullet('If required by law or legal authorities'),
            _buildBullet('To protect user safety and platform integrity'),
            const Divider(height: 32),

            _buildSectionTitle('5. Data Security'),
            _buildParagraph(
              'We use reasonable technical and administrative measures to protect your information, including:',
            ),
            _buildBullet('Secure authentication via OTP'),
            _buildBullet('Encrypted data storage where applicable'),
            _buildBullet('Limited access to sensitive information'),
            _buildNote('However, no system is 100% secure, and we cannot guarantee absolute security.'),
            const Divider(height: 32),

            _buildSectionTitle('6. User Anonymity'),
            _buildParagraph('Texme is designed for maximum privacy:'),
            _buildBullet('No real name required'),
            _buildBullet('No profile photo required'),
            _buildBullet('No public profiles'),
            _buildBullet('Limited personal data collection'),
            const Divider(height: 32),

            _buildSectionTitle('7. Age Restriction'),
            _buildParagraph('Texme is intended only for users 18 years and above.'),
            _buildParagraph('We do not knowingly allow minors to use the app.'),
            const Divider(height: 32),

            _buildSectionTitle('8. Account Deletion'),
            _buildParagraph('Users may request account deletion.'),
            _buildParagraph('Upon deletion:'),
            _buildBullet('Personal data will be removed or anonymized'),
            _buildBullet('Chat history may be retained only if required by law'),
            const Divider(height: 32),

            _buildSectionTitle('9. Changes to This Policy'),
            _buildParagraph('We may update this Privacy Policy from time to time.'),
            _buildParagraph('Changes will be posted within the app or on our official platform.'),
            const Divider(height: 32),

            _buildSectionTitle('10. Contact Us'),
            _buildParagraph('If you have questions or concerns about this Privacy Policy, contact us at:'),
            _buildContactInfo('Email:', 'texme54321@gmail.com'),
            _buildContactInfo('App Name:', 'Texme'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: AppTextStyles.h2.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: AppTextStyles.h3.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        text,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNote(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.info,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
