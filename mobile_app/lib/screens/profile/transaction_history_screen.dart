import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

/// Transaction History Screen
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final ApiService _api = ApiService.instance;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    if (auth.isMale) {
      // Load coin purchase history for males
      final response = await _api.getCoinHistory();
      if (response.success && response.data != null) {
        final transactions = response.data['transactions'] as List? ?? [];
        setState(() {
          _transactions = transactions.map((t) => t as Map<String, dynamic>).toList();
        });
      }
    } else {
      // Load earning/wallet history for females
      final response = await _api.getWalletHistory();
      if (response.success && response.data != null) {
        final transactions = response.data['transactions'] as List? ?? [];
        setState(() {
          _transactions = transactions.map((t) => t as Map<String, dynamic>).toList();
        });
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isMale = auth.isMale;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMale ? 'Purchase History' : 'Earning History'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? _buildEmptyState(isMale)
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return _TransactionCard(
                        transaction: transaction,
                        isMale: isMale,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isMale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMale ? Icons.shopping_cart_outlined : Icons.account_balance_wallet_outlined,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isMale ? 'No purchases yet' : 'No earnings yet',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isMale 
                ? 'Your coin purchases will appear here'
                : 'Your chat earnings will appear here',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Transaction Card Widget
class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isMale;

  const _TransactionCard({
    required this.transaction,
    required this.isMale,
  });

  @override
  Widget build(BuildContext context) {
    final type = transaction['type']?.toString() ?? '';
    final amount = transaction['amount']?.toString() ?? '0';
    final coins = transaction['coins']?.toString() ?? '';
    final description = transaction['description']?.toString() ?? '';
    final status = transaction['status']?.toString() ?? '';
    final createdAt = transaction['created_at']?.toString() ?? '';
    
    // Determine icon and color based on type
    IconData icon;
    Color color;
    String title;
    String subtitle;
    
    if (isMale) {
      // Male: Coin transactions
      switch (type) {
        case 'purchase':
          icon = Icons.add_circle;
          color = AppColors.success;
          title = '+$coins Coins';
          subtitle = 'Purchased for ₹$amount';
          break;
        case 'spent':
          icon = Icons.remove_circle;
          color = AppColors.error;
          title = '-$coins Coins';
          subtitle = description.isNotEmpty ? description : 'Chat';
          break;
        default:
          icon = Icons.monetization_on;
          color = AppColors.primary;
          title = '$coins Coins';
          subtitle = description;
      }
    } else {
      // Female: Wallet transactions
      switch (type) {
        case 'earning':
          icon = Icons.add_circle;
          color = AppColors.success;
          title = '+₹$amount';
          subtitle = description.isNotEmpty ? description : 'Chat earning';
          break;
        case 'withdrawal':
          icon = Icons.remove_circle;
          color = AppColors.warning;
          title = '-₹$amount';
          subtitle = 'Withdrawn';
          break;
        default:
          icon = Icons.account_balance_wallet;
          color = AppColors.primary;
          title = '₹$amount';
          subtitle = description;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Date & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(createdAt),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              if (status.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: _getStatusColor(status),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
