import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

// Razorpay import - only works on mobile
// ignore: depend_on_referenced_packages
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Coin Package Model
class CoinPackage {
  final int coins;
  final int price;
  final int discount;
  final bool isPopular;

  const CoinPackage({
    required this.coins,
    required this.price,
    required this.discount,
    this.isPopular = false,
  });
}

/// Coin Purchase Screen (Male Only)
class CoinPurchaseScreen extends StatefulWidget {
  const CoinPurchaseScreen({super.key});

  @override
  State<CoinPurchaseScreen> createState() => _CoinPurchaseScreenState();
}

class _CoinPurchaseScreenState extends State<CoinPurchaseScreen> {
  final ApiService _api = ApiService.instance;
  
  // Razorpay instance (null on web)
  Razorpay? _razorpay;
  
  // Available coin packages
  static const List<CoinPackage> _packages = [
    CoinPackage(coins: 40, price: 25, discount: 30),
    CoinPackage(coins: 90, price: 49, discount: 30),
    CoinPackage(coins: 200, price: 64, discount: 30),
    CoinPackage(coins: 440, price: 129, discount: 20),
    CoinPackage(coins: 1200, price: 299, discount: 30, isPopular: true),
    CoinPackage(coins: 3500, price: 699, discount: 40),
  ];

  int _selectedIndex = 0;
  bool _isLoading = false;

  CoinPackage get _selectedPackage => _packages[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _initRazorpay();
  }

  void _initRazorpay() {
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment Success: ${response.paymentId}');
    
    // NOTE:
    // Backend credits coins after gateway confirmation (typically webhook).
    // For local/dev testing, webhooks won't reach your machine unless you use a public URL.
    // So we just refresh profile and show a confirmation message.
    if (!mounted) return;

    await Provider.of<AuthProvider>(context, listen: false).refreshProfile();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment received. Coins will reflect after server confirmation.'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Error: ${response.code} - ${response.message}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet selected: ${response.walletName}'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  Future<void> _purchaseCoins() async {
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    if (kIsWeb) {
      // Web: Show message that payment only works on mobile
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment is only available on the mobile app'),
          backgroundColor: AppColors.warning,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    // 1) Ask backend to create an order (uses /coins/purchase with package_index)
    final orderResp = await _api.initiateCoinPurchase(_selectedIndex);
    if (!orderResp.success || orderResp.data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderResp.message ?? 'Failed to start payment'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final order = orderResp.data['order'] as Map?;
    if (order == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment gateway order missing from server response'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    // 2) Open Razorpay (only supported gateway in this Flutter UI right now)
    final keyId = (order['key_id'] ?? '') as String;
    final orderId = (order['order_id'] ?? '') as String;
    final amount = order['amount']; // paise

    if (keyId.isEmpty || orderId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server is not configured for Razorpay (missing key/order). Use admin to add coins for testing.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final options = {
      'key': keyId,
      'order_id': orderId,
      'amount': amount,
      'name': order['name'] ?? 'Texme',
      'description': order['description'] ?? '${_selectedPackage.coins} Coins',
      'prefill': {
        'contact': user?.phone ?? '',
        'email': '',
      },
      'theme': {
        'color': '#6C63FF',
      },
      'external': {
        'wallets': ['paytm', 'phonepe', 'gpay'],
      },
    };

    try {
      _razorpay?.open(options);
    } catch (e) {
      print('Razorpay Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening payment: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Wallet', style: AppTextStyles.h3),
        centerTitle: true,
        actions: [
          // Current Balance
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.md),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${user?.coinBalance ?? 0}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Coin Packages Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: _packages.length,
                itemBuilder: (context, index) {
                  final package = _packages[index];
                  final isSelected = index == _selectedIndex;
                  
                  return _CoinPackageCard(
                    package: package,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedIndex = index),
                  );
                },
              ),
            ),
          ),

          // Purchase Button
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
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _purchaseCoins,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          'Add ${_selectedPackage.coins} Coins',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white,
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
}

/// Individual Coin Package Card
class _CoinPackageCard extends StatelessWidget {
  final CoinPackage package;
  final bool isSelected;
  final VoidCallback onTap;

  const _CoinPackageCard({
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppColors.primary.withOpacity(0.2) 
                  : AppColors.shadow.withOpacity(0.1),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Popular Badge
            if (package.isPopular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(AppRadius.md - 2),
                      bottomLeft: Radius.circular(AppRadius.sm),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        'Popular',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Column(
              children: [
                // Coin Icon & Amount Section
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Coin Icon
                        Text(
                          '🪙',
                          style: TextStyle(
                            fontSize: package.coins >= 1000 ? 22 : 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Coin Amount
                        Text(
                          '${package.coins}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: package.coins >= 1000 ? 16 : 18,
                          ),
                        ),
                        Text(
                          'Coins',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Price Section with Gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryLight,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppRadius.md - 2),
                      bottomRight: Radius.circular(AppRadius.md - 2),
                    ),
                  ),
                  child: Text(
                    '₹${package.price}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
