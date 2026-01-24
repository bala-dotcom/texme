import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import 'guidelines_screen.dart';
import 'refund_policy_screen.dart';
import 'terms_of_service_screen.dart';

/// Help & Support Screen
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.support_agent,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '📌 Help & Support',
                    style: AppTextStyles.h2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "We're here to help you have a smooth and safe experience on our platform.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Contact Support Card
            _SupportCard(
              icon: Icons.email_outlined,
              iconColor: AppColors.info,
              title: '📩 Contact Support',
              description: 'Facing an issue or need personal assistance?\nOur support team is ready to help you.',
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  _ContactItem(
                    icon: Icons.email,
                    label: 'Email',
                    value: 'texme54321@gmail.com',
                    onTap: () => _launchEmail('texme54321@gmail.com'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ContactItem(
                    icon: Icons.access_time,
                    label: 'Support Hours',
                    value: '10:00 AM – 6:00 PM (IST)',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ContactItem(
                    icon: Icons.timer_outlined,
                    label: 'Response Time',
                    value: 'Within 24 hours',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // FAQs Section
            _SupportCard(
              icon: Icons.help_outline,
              iconColor: AppColors.warning,
              title: '❓ Frequently Asked Questions',
              description: 'Find quick answers to common questions.',
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  _FaqItem(
                    question: 'How do I purchase coins?',
                    answer: 'Go to Profile > Wallet Balance and select a coin package to purchase.',
                  ),
                  _FaqItem(
                    question: 'How do I start a chat?',
                    answer: 'Browse available users from the Home screen and tap on "Chat" to send a request.',
                  ),
                  _FaqItem(
                    question: 'How are coins deducted?',
                    answer: 'Coins are deducted based on chat duration. The first 10 seconds are free, then 10 coins per minute.',
                  ),
                  _FaqItem(
                    question: 'How do I withdraw my earnings?',
                    answer: 'Go to Profile > My Wallet and tap on "Withdraw" to transfer earnings to your bank account.',
                  ),
                  _FaqItem(
                    question: 'How do I delete my account?',
                    answer: 'Go to Profile > Privacy Policy > Delete Account. Select a reason and confirm deletion.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Safety Tips Section
            _SupportCard(
              icon: Icons.shield_outlined,
              iconColor: AppColors.success,
              title: '🛡️ Safety Tips',
              description: 'Stay safe while using Texme.',
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  _SafetyTip(text: 'Never share personal contact details'),
                  _SafetyTip(text: 'Report abusive or inappropriate behavior'),
                  _SafetyTip(text: 'Do not share financial information'),
                  _SafetyTip(text: 'Block users who make you uncomfortable'),
                  _SafetyTip(text: 'Keep conversations within the app'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Legal Section
            _SupportCard(
              icon: Icons.gavel_outlined,
              iconColor: AppColors.primary,
              title: '⚖️ Policies & Guidelines',
              description: 'Important legal documents and community rules.',
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  _LegalLink(
                    title: 'Community Guidelines',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GuidelinesScreen()),
                    ),
                  ),
                  _LegalLink(
                    title: 'Refund & Cancellation',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RefundPolicyScreen()),
                    ),
                  ),
                  _LegalLink(
                    title: 'Terms of Service',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Report Issue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchEmail('texme54321@gmail.com'),
                icon: const Icon(Icons.report_problem_outlined, color: Colors.white),
                label: const Text(
                  'Report an Issue',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Texme Support Request',
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}

/// Support Card Widget
class _SupportCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final Widget child;

  const _SupportCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Contact Item Widget
class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              '$label: ',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: onTap != null ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

/// FAQ Item Widget
class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              widget.answer,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        Divider(color: AppColors.border.withOpacity(0.5)),
      ],
    );
  }
}

/// Safety Tip Widget
class _SafetyTip extends StatelessWidget {
  final String text;

  const _SafetyTip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Legal Link Widget
class _LegalLink extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _LegalLink({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.bodyMedium),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
