import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common/widgets.dart';

/// Bank Details Screen
class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankController = TextEditingController();
  final _upiController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  Future<void> _loadBankDetails() async {
    final response = await ApiService.instance.getBankDetails();
    
    if (!mounted) return;
    
    setState(() => _isLoadingDetails = false);
    
    if (response.success && response.data['has_bank_details'] == true) {
      final details = response.data['bank_details'];
      if (details != null) {
        _nameController.text = details['account_name'] ?? '';
        _accountController.text = details['account_number'] ?? '';
        _ifscController.text = details['ifsc'] ?? '';
        _bankController.text = details['bank_name'] ?? '';
        _upiController.text = details['upi_id'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _bankController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _saveBankDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await ApiService.instance.updateBankDetails(
      accountName: _nameController.text.trim(),
      accountNumber: _accountController.text.trim(),
      ifsc: _ifscController.text.trim().toUpperCase(),
      bankName: _bankController.text.trim(),
      upiId: _upiController.text.trim().isNotEmpty
          ? _upiController.text.trim()
          : null,
    );

    setState(() => _isLoading = false);

    if (response.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank details saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to save'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bank Details', style: AppTextStyles.h4),
        centerTitle: true,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading || _isLoadingDetails,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: AppColors.info, size: 24),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Your bank details are encrypted and secure.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Account Holder Name
                CustomTextField(
                  label: 'Account Holder Name *',
                  hint: 'As per bank records',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Account Number
                CustomTextField(
                  label: 'Account Number *',
                  hint: 'Enter account number',
                  controller: _accountController,
                  keyboardType: TextInputType.number,
                  maxLength: 18,
                ),
                const SizedBox(height: AppSpacing.lg),

                // IFSC Code
                CustomTextField(
                  label: 'IFSC Code *',
                  hint: 'E.g., SBIN0001234',
                  controller: _ifscController,
                  keyboardType: TextInputType.text,
                  maxLength: 11,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Bank Name
                CustomTextField(
                  label: 'Bank Name *',
                  hint: 'E.g., State Bank of India',
                  controller: _bankController,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: AppSpacing.lg),

                // UPI ID (Optional)
                CustomTextField(
                  label: 'UPI ID (Optional)',
                  hint: 'E.g., yourname@upi',
                  controller: _upiController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 40),

                // Save Button
                PrimaryButton(
                  text: 'Save Bank Details',
                  onPressed: _saveBankDetails,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
