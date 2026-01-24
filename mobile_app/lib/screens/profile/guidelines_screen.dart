import 'package:flutter/material.dart';
import '../../config/theme.dart';

class GuidelinesScreen extends StatelessWidget {
  const GuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Guidelines'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle('Community Guidelines & Content Moderation'),
            _buildParagraph(
              'At Texme, we strive to maintain a safe, respectful, and positive environment for all our users. By using the App, you agree to follow these guidelines.',
            ),
            const Divider(height: 32),

            _buildSectionTitle('1. Respectful Interactions'),
            _buildBullet('Treat all users with respect and dignity.'),
            _buildBullet('Harassment, bullying, or abusive behavior is strictly prohibited.'),
            _buildBullet('Do not use hate speech or discriminate based on race, religion, gender, or orientation.'),
            const Divider(height: 32),

            _buildSectionTitle('2. Content Restrictions'),
            _buildBullet('Sharing of obscene, pornographic, or sexually explicit content is prohibited.'),
            _buildBullet('Do not share violent or graphic content.'),
            _buildBullet('Sharing personal contact details (phone numbers, addresses) to move chats off-platform is discouraged for your own safety.'),
            const Divider(height: 32),

            _buildSectionTitle('3. Illegal Activities'),
            _buildBullet('Any form of solicitation, fraud, or illegal activity will result in an immediate ban.'),
            _buildBullet('Do not engage in or promote drug use, human trafficking, or any other criminal acts.'),
            const Divider(height: 32),

            _buildSectionTitle('4. Content Moderation'),
            _buildParagraph(
              'To ensure the safety of our community, Texme employs a multi-layered content moderation system:',
            ),
            _buildBullet('Automated Filtering: Our systems detect and block prohibited keywords and explicit content.'),
            _buildBullet('Human Review: Reported content and suspicious activities are reviewed by our moderation team.'),
            _buildBullet('Reporting System: Users are encouraged to report any violations using the "Report" button in chats or profiles.'),
            _buildNote('Violation of these guidelines may lead to temporary suspension or permanent account termination without refund.'),
            const Divider(height: 32),

            _buildSectionTitle('5. Appeal Process'),
            _buildParagraph(
              'If your account has been suspended and you believe it was an error, you may contact our support team at support@texme.online to request an appeal.',
            ),
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
}
