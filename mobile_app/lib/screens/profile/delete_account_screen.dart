import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/phone_login_screen.dart';

/// Delete Account Screen
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isExpanded = false;
  String? _selectedReason;
  bool _isLoading = false;

  final List<String> _reasons = [
    'Not able to find Texme',
    'Abusive language',
    'Texme not polite',
    'Texme not interested',
    'Ask for money',
    'Other',
  ];

  final List<String> _importantInfoShort = [
    'Information related to account will be kept for 30 days and will be completely purged after no activity for continuous 30 days',
    'After the account is deleted, you will no longer be able to log in or use the account, and the account cannot be recovered.',
  ];

  final List<String> _importantInfoFull = [
    'Information related to account will be kept for 30 days and will be completely purged after no activity for continuous 30 days',
    'After the account is deleted, you will no longer be able to log in or use the account, and the account cannot be recovered.',
    'After the account is deleted, your personal data and account-related information (including but not limited to user name, transaction history, coins, etc.) will be permanently deleted and cannot be retrieved.',
    'Before the account is deleted, coins must be consumed or withdrawn/ transferred.',
    'If account is deleted without using/ transferring coins, Texme coins, they will be lost forever and cannot be recovered.',
    'Texme has the right to stop the deletion process if the account is subject to litigation and being investigated by a government body without seeking user approval.',
    'Deleting your account does not constitute exemption or mitigation of responsibility for behaviour committed prior to account\'s deletion',
  ];

  @override
  Widget build(BuildContext context) {
    final infoList = _isExpanded ? _importantInfoFull : _importantInfoShort;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Delete Account',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Important Information Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Warning Icon
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF9800),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        // Title
                        const Text(
                          'Important Information',
                          style: TextStyle(
                            color: Color(0xFFFF9800),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Info Points
                        ...infoList.map((info) => _buildInfoPoint(info)),
                        
                        const SizedBox(height: AppSpacing.md),
                        
                        // View More/Less Button
                        GestureDetector(
                          onTap: () {
                            setState(() => _isExpanded = !_isExpanded);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isExpanded ? 'View less' : 'View more',
                                style: const TextStyle(
                                  color: Color(0xFFFF9800),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                _isExpanded 
                                    ? Icons.keyboard_arrow_up 
                                    : Icons.keyboard_arrow_down,
                                color: const Color(0xFFFF9800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Reason Selection Title
                  Text(
                    'Please select at least one reason for deleting your account',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Reason Chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _reasons.map((reason) {
                      final isSelected = _selectedReason == reason;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedReason = reason);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.white 
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFFFF9800) 
                                  : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            reason,
                            style: TextStyle(
                              color: isSelected 
                                  ? AppColors.textPrimary 
                                  : AppColors.textSecondary,
                              fontWeight: isSelected 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Help Text
                  Center(
                    child: Text(
                      'Need Help? Please write to:',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // TODO: Open email
                      },
                      child: const Text(
                        'texme54321@gmail.com',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Delete Button
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _selectedReason == null || _isLoading
                      ? null
                      : _deleteAccount,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _selectedReason == null 
                          ? AppColors.textLight 
                          : AppColors.error,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Delete Account',
                          style: TextStyle(
                            color: _selectedReason == null 
                                ? AppColors.textLight 
                                : AppColors.error,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF424242),
              shape: BoxShape.rectangle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Call API to delete account with reason
      // await ApiService.instance.deleteAccount(reason: _selectedReason);
      
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.logout();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }
}
