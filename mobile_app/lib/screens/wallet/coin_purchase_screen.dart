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
  final int id;
  final String label;
  final int coins;
  final int price;
  final int bonus;
  final bool isActive;

  const CoinPackage({
    required this.id,
    required this.label,
    required this.coins,
    required this.price,
    this.bonus = 0,
    this.isActive = true,
  });

  factory CoinPackage.fromJson(Map<String, dynamic> json) {
    return CoinPackage(
      id: json['id'],
      label: json['label'] ?? 'Coin Pack',
      coins: json['coins'],
      price: json['price'],
      bonus: json['bonus'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
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
  
  List<CoinPackage> _packages = [];
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isProcessing = false;

  CoinPackage? get _selectedPackage => _packages.isNotEmpty ? _packages[_selectedIndex] : null;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _loadPackages();
  }

  void _initRazorpay() {
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.getCoinPackages();
      if (response.success) {
        final List<dynamic> packagesJson = response.data['packages'];
        setState(() {
          _packages = packagesJson.map((j) => CoinPackage.fromJson(j)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load packages: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment Success: ${response.paymentId}');
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
    setState(() => _isProcessing = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
  }

  Future<void> _purchaseCoins() async {
    if (_selectedPackage == null) return;
    
    setState(() => _isProcessing = true);

    try {
      final response = await _api.initiateCoinPurchase(_selectedPackage!.id);
      
      if (response.success) {
        final gateway = response.data['gateway'];
        final order = response.data['order'];

        if (gateway == 'razorpay') {
          var options = {
            'key': order['key_id'],
            'amount': order['amount'],
            'name': order['name'],
            'description': order['description'],
            'order_id': order['order_id'],
            'prefill': {
              'contact': Provider.of<AuthProvider>(context, listen: false).user?.phone ?? '',
            },
            'external': {
              'wallets': ['paytm']
            }
          };

          _razorpay?.open(options);
        } else {
          // Other gateways or web flow would be handled here
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gateway not supported on this device')),
            );
          }
          setState(() => _isProcessing = false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Failed to initiate purchase')),
          );
        }
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() => _isProcessing = false);
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : Column(
        children: [
          if (_packages.isEmpty)
            const Expanded(
              child: Center(child: Text('No packages available')),
            )
          else
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

          if (_packages.isNotEmpty)
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
                    onPressed: _isProcessing ? null : _purchaseCoins,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'Add ${_selectedPackage?.coins ?? 0} Coins',
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
            // Bonus Badge
            if (package.bonus > 0)
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
                  child: Text(
                    '+${package.bonus} Bonus',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
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
