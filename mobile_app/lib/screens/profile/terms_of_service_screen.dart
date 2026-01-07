import 'package:flutter/material.dart';
import '../../config/theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle('Terms and Conditions'),
            _buildParagraph(
              'Welcome to Texme ("App"). These Terms and Conditions ("Terms") govern your access to and use of the Texme mobile application operated by Texme ("we", "us", "our").',
            ),
            _buildParagraph(
              'By downloading, registering, or using Texme, you agree to be legally bound by these Terms. If you do not agree, please do not use the App.',
            ),
            const Divider(height: 32),

            _buildSectionTitle('1. Eligibility'),
            _buildBullet('You must be 18 years or older to use Texme.'),
            _buildBullet('By using the App, you confirm that you are legally eligible under Indian law.'),
            _buildBullet('Texme does not knowingly allow minors to register or use the App.'),
            const Divider(height: 32),

            _buildSectionTitle('2. Nature of Service'),
            _buildBullet('Texme is a one-to-one private messaging application.'),
            _buildBullet('The App does not require profile photos.'),
            _buildBullet('Male users are not required to provide name, age, or interests.'),
            _buildBullet('Female users must provide age and interests to use the platform.'),
            _buildBullet('Texme does not guarantee matches, responses, or earnings.'),
            const Divider(height: 32),

            _buildSectionTitle('3. Account Registration'),
            _buildBullet('Login is done using mobile number and OTP verification only.'),
            _buildBullet('Users are responsible for maintaining the confidentiality of their account.'),
            _buildBullet('You are responsible for all activities conducted through your account.'),
            const Divider(height: 32),

            _buildSectionTitle('4. Payments, Coins & Earnings'),
            _buildSubTitle('4.1 Coin Purchases'),
            _buildBullet('Male users may purchase coins to initiate or continue chats.'),
            _buildBullet('All purchases are non-transferable and non-refundable, unless required by law.'),
            
            _buildSubTitle('4.2 Earnings for Female Users'),
            _buildBullet('Female users may earn money based on chat activity.'),
            _buildBullet('Earnings are subject to:'),
            _buildSubBullet('Platform rules'),
            _buildSubBullet('Minimum withdrawal limits'),
            _buildSubBullet('Verification requirements'),
            _buildBullet('Texme reserves the right to withhold payouts in case of fraud, misuse, or violation of Terms.'),
            
            _buildSubTitle('4.3 Payment Gateways'),
            _buildBullet('Payments and payouts are processed through RBI-compliant third-party payment gateways (UPI, cards, wallets, etc.).'),
            _buildBullet('Texme does not store payment credentials such as card numbers or UPI PINs.'),
            _buildBullet('Texme is not responsible for failures, delays, or errors caused by payment providers.'),
            const Divider(height: 32),

            _buildSectionTitle('5. User Conduct'),
            _buildParagraph('You agree NOT to:'),
            _buildBullet('Use the App for illegal, abusive, or fraudulent purposes'),
            _buildBullet('Share obscene, harassing, hateful, or threatening content'),
            _buildBullet('Impersonate another person or provide false information'),
            _buildBullet('Attempt to exploit payment systems or earnings'),
            _buildBullet('Share personal contact details for off-platform transactions'),
            _buildBullet('Use bots, automation, or unauthorized tools'),
            _buildWarning('Violation may result in suspension or permanent ban without notice.'),
            const Divider(height: 32),

            _buildSectionTitle('6. Content & Communication'),
            _buildBullet('All chats are private one-to-one communications.'),
            _buildBullet('You are solely responsible for the content you send or receive.'),
            _buildBullet('Texme does not endorse or guarantee the accuracy of user content.'),
            _buildBullet('Texme reserves the right to monitor or review chats only when required for safety, fraud prevention, or legal compliance.'),
            const Divider(height: 32),

            _buildSectionTitle('7. Privacy & Data Protection'),
            _buildBullet('Your privacy is important to us.'),
            _buildBullet('Personal data is handled in accordance with our Privacy Policy and applicable Indian laws including:'),
            _buildSubBullet('Digital Personal Data Protection Act, 2023'),
            _buildSubBullet('Information Technology Act, 2000'),
            _buildBullet('By using Texme, you consent to data processing as described in our Privacy Policy.'),
            const Divider(height: 32),

            _buildSectionTitle('8. Account Suspension & Termination'),
            _buildParagraph('Texme may suspend or terminate your account if:'),
            _buildBullet('You violate these Terms'),
            _buildBullet('You engage in suspicious or illegal activity'),
            _buildBullet('Required by law or regulatory authorities'),
            _buildBullet('The App or services are discontinued'),
            _buildParagraph('You may also stop using the App at any time.'),
            const Divider(height: 32),

            _buildSectionTitle('9. Refund & Cancellation Policy'),
            _buildBullet('Coin purchases are generally non-refundable.'),
            _buildBullet('Refunds may be issued only if:'),
            _buildSubBullet('Required by law'),
            _buildSubBullet('Payment failure with no service delivery'),
            _buildNote('Decisions regarding refunds are final.'),
            const Divider(height: 32),

            _buildSectionTitle('10. Disclaimer of Warranties'),
            _buildBullet('Texme is provided on an "as is" and "as available" basis.'),
            _buildBullet('We do not guarantee uninterrupted, error-free, or secure service.'),
            _buildBullet('Texme does not guarantee income, chat availability, or user behavior.'),
            const Divider(height: 32),

            _buildSectionTitle('11. Limitation of Liability'),
            _buildParagraph('To the maximum extent permitted by law:'),
            _buildBullet('Texme shall not be liable for indirect, incidental, or consequential damages'),
            _buildBullet('Texme is not responsible for user interactions, losses, or disputes'),
            _buildBullet('Texme\'s total liability shall not exceed the amount paid by you in the last 30 days'),
            const Divider(height: 32),

            _buildSectionTitle('12. Third-Party Services'),
            _buildParagraph('The App may rely on third-party services (payment gateways, hosting, analytics). Texme is not responsible for their actions, policies, or downtime.'),
            const Divider(height: 32),

            _buildSectionTitle('13. Changes to Terms'),
            _buildParagraph('We reserve the right to update these Terms at any time. Continued use of Texme after changes means you accept the updated Terms.'),
            const Divider(height: 32),

            _buildSectionTitle('14. Governing Law & Jurisdiction'),
            _buildParagraph('These Terms shall be governed by and interpreted under the laws of India.'),
            _buildParagraph('All disputes shall be subject to the exclusive jurisdiction of the courts of Tamil Nadu, India.'),
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

  Widget _buildSubBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textLight,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                height: 1.5,
                color: AppColors.textSecondary,
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

  Widget _buildWarning(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
