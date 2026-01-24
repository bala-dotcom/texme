import 'package:flutter/material.dart';
import '../../config/theme.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refund & Cancellation'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle('Refund & Cancellation Policy'),
            _buildParagraph(
              'Thank you for using Texme. We appreciate your interest in our services. Please read our refund and cancellation policy carefully.',
            ),
            const Divider(height: 32),

            _buildSectionTitle('1. Coin Purchases'),
            _buildParagraph(
              'All coin purchases made on Texme are final and non-refundable, except as expressly stated in this policy or required by applicable law.',
            ),
            _buildBullet('Once coins are credited to your account, they cannot be converted back to real currency or refunded.'),
            _buildBullet('Purchased coins have no expiration date as long as your account remains active.'),
            const Divider(height: 32),

            _buildSectionTitle('2. Exceptions for Refunds'),
            _buildParagraph(
              'Refunds may be considered in the following limited circumstances:',
            ),
            _buildBullet('Technical Errors: If your payment was successful but coins were not credited to your account due to a technical glitch.'),
            _buildBullet('Duplicate Payments: If you were charged twice for the same transaction due to a payment gateway error.'),
            _buildBullet('Legal Requirements: Where required by local laws or regulations.'),
            const Divider(height: 32),

            _buildSectionTitle('3. Refund Process'),
            _buildParagraph(
              'To request a refund for a missing credit or duplicate payment:',
            ),
            _buildBullet('Contact support@texme.online within 48 hours of the transaction.'),
            _buildBullet('Provide proof of payment (transaction ID, screenshot).'),
            _buildBullet('Approved refunds will be processed within 5-7 business days to the original payment method.'),
            const Divider(height: 32),

            _buildSectionTitle('4. Account Cancellation'),
            _buildBullet('You can stop using the App and delete your account at any time via the Privacy Settings.'),
            _buildBullet('Upon account deletion, any remaining coin balance will be forfeited and is non-refundable.'),
            _buildBullet('Female user earnings will be processed only if the minimum withdrawal limit has been reached prior to account deletion.'),
            const Divider(height: 32),

            _buildSectionTitle('5. Changes to Policy'),
            _buildParagraph(
              'Texme reserves the right to modify this Refund & Cancellation Policy at any time. Any changes will be updated on this page.',
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
}
