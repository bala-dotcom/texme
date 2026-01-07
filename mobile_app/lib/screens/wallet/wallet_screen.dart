import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/widgets.dart';
import 'bank_details_screen.dart';

/// Wallet Screen (Female Only)
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _api = ApiService.instance;

  double _balance = 0;
  double _totalEarned = 0;
  double _totalWithdrawn = 0;
  double _minWithdrawal = 500;
  bool _hasBankDetails = false;
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);

    // Load balance
    final balanceResponse = await _api.getWalletBalance();
    if (balanceResponse.success) {
      setState(() {
        _balance =
            double.tryParse(balanceResponse.data['balance'].toString()) ?? 0;
        _totalEarned =
            double.tryParse(balanceResponse.data['total_earned'].toString()) ?? 0;
        _totalWithdrawn =
            double.tryParse(balanceResponse.data['total_withdrawn'].toString()) ?? 0;
        _minWithdrawal =
            double.tryParse(balanceResponse.data['min_withdrawal'].toString()) ?? 500;
        _hasBankDetails = balanceResponse.data['has_bank_details'] ?? false;
      });
    }

    // Load history
    final historyResponse = await _api.getWalletHistory();
    if (historyResponse.success && historyResponse.data['transactions'] != null) {
      final List txns = historyResponse.data['transactions'];
      setState(() {
        _transactions = txns.map((t) => Transaction.fromJson(t)).toList();
      });
    }

    setState(() => _isLoading = false);
  }

  void _requestWithdrawal() {
    if (!_hasBankDetails) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add bank details first'),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BankDetailsScreen()),
      );
      return;
    }

    if (_balance < _minWithdrawal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum withdrawal is ₹${_minWithdrawal.toStringAsFixed(0)}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WithdrawalSheet(
        maxAmount: _balance,
        minAmount: _minWithdrawal,
        onSubmit: _submitWithdrawal,
      ),
    );
  }

  Future<void> _submitWithdrawal(double amount) async {
    Navigator.pop(context);

    final response = await _api.requestWithdrawal(amount);

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal requested successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadWalletData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Failed to request withdrawal'),
          backgroundColor: AppColors.error,
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
        title: Text('Wallet', style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BankDetailsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWalletData,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.success, Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Balance',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '₹${_balance.toStringAsFixed(2)}',
                            style: AppTextStyles.h1.copyWith(
                              color: Colors.white,
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Earned',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      '₹${_totalEarned.toStringAsFixed(0)}',
                                      style: AppTextStyles.h4.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Withdrawn',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      '₹${_totalWithdrawn.toStringAsFixed(0)}',
                                      style: AppTextStyles.h4.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Withdraw Button
                    PrimaryButton(
                      text: 'Withdraw Funds',
                      icon: Icons.account_balance_wallet,
                      onPressed: _requestWithdrawal,
                    ),

                    if (!_hasBankDetails) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppColors.warning, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Add bank details to withdraw funds',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),

                    // Transaction History
                    Text('Recent Transactions', style: AppTextStyles.h4),
                    const SizedBox(height: AppSpacing.md),

                    if (_transactions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            children: [
                              const Icon(Icons.history,
                                  size: 48, color: AppColors.textLight),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'No transactions yet',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppColors.divider),
                        itemBuilder: (context, index) {
                          final txn = _transactions[index];
                          return _TransactionItem(transaction: txn);
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Transaction Item Widget
class _TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.type == 'earning';
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (isPositive ? AppColors.success : AppColors.error)
              .withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPositive ? Icons.add : Icons.remove,
          color: isPositive ? AppColors.success : AppColors.error,
        ),
      ),
      title: Text(
        isPositive
            ? 'Chat Earning'
            : transaction.type == 'withdrawal'
                ? 'Withdrawal'
                : 'Deduction',
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _formatDate(transaction.createdAt),
        style: AppTextStyles.caption,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isPositive ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isPositive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            transaction.status.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: transaction.isSuccess
                  ? AppColors.success
                  : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Withdrawal Bottom Sheet
class _WithdrawalSheet extends StatefulWidget {
  final double maxAmount;
  final double minAmount;
  final Function(double) onSubmit;

  const _WithdrawalSheet({
    required this.maxAmount,
    required this.minAmount,
    required this.onSubmit,
  });

  @override
  State<_WithdrawalSheet> createState() => _WithdrawalSheetState();
}

class _WithdrawalSheetState extends State<_WithdrawalSheet> {
  final TextEditingController _amountController = TextEditingController();
  bool _isValid = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _validate(String value) {
    final amount = double.tryParse(value) ?? 0;
    setState(() {
      _isValid = amount >= widget.minAmount && amount <= widget.maxAmount;
    });
  }

  void _setMax() {
    _amountController.text = widget.maxAmount.toStringAsFixed(0);
    _validate(_amountController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Withdraw Funds', style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.lg),

          // Amount Input
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Amount',
                  hint: 'Enter amount',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text('₹', style: TextStyle(fontSize: 18)),
                  ),
                  onChanged: _validate,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              TextButton(
                onPressed: _setMax,
                child: const Text('MAX'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Min: ₹${widget.minAmount.toStringAsFixed(0)} | Max: ₹${widget.maxAmount.toStringAsFixed(0)}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.xl),

          PrimaryButton(
            text: 'Request Withdrawal',
            onPressed: _isValid
                ? () => widget.onSubmit(double.parse(_amountController.text))
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
