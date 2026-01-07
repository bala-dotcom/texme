/// Helper to safely parse int
int _parseInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.floor();
  return int.tryParse(value.toString()) ?? defaultValue;
}

/// Helper to safely parse double
double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? defaultValue;
}

/// Coin Package Model
class CoinPackage {
  final int coins;
  final int price;
  final int bonus;
  final String label;

  CoinPackage({
    required this.coins,
    required this.price,
    required this.bonus,
    required this.label,
  });

  int get totalCoins => coins + bonus;
  String get priceFormatted => '₹$price';
  String get coinsFormatted => bonus > 0 ? '$coins + $bonus' : '$coins';

  factory CoinPackage.fromJson(Map<String, dynamic> json) {
    return CoinPackage(
      coins: _parseInt(json['coins']),
      price: _parseInt(json['price']),
      bonus: _parseInt(json['bonus']),
      label: json['label'] ?? 'Package',
    );
  }
}

/// Transaction Model
class Transaction {
  final int id;
  final String type;
  final double amount;
  final int? coins;
  final String status;
  final int? chatMinutes;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    this.coins,
    required this.status,
    this.chatMinutes,
    required this.createdAt,
  });

  bool get isCoinPurchase => type == 'coin_purchase';
  bool get isCoinDeduction => type == 'coin_deduction';
  bool get isEarning => type == 'earning';
  bool get isWithdrawal => type == 'withdrawal';
  bool get isSuccess => status == 'success';

  String get amountFormatted => isEarning || isWithdrawal
      ? '₹${amount.toStringAsFixed(0)}'
      : '${coins ?? 0} coins';

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: _parseInt(json['id']),
      type: json['type'] ?? 'unknown',
      amount: _parseDouble(json['amount']),
      coins: json['coins'] != null ? _parseInt(json['coins']) : null,
      status: json['status'] ?? 'pending',
      chatMinutes: json['chat_minutes'] != null ? _parseInt(json['chat_minutes']) : null,
      createdAt: json['created_at'] != null 
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// Withdrawal Model
class Withdrawal {
  final int id;
  final double amount;
  final String status;
  final String? bankName;
  final String? accountLast4;
  final DateTime requestedAt;
  final DateTime? processedAt;

  Withdrawal({
    required this.id,
    required this.amount,
    required this.status,
    this.bankName,
    this.accountLast4,
    required this.requestedAt,
    this.processedAt,
  });

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';

  String get amountFormatted => '₹${amount.toStringAsFixed(0)}';

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: _parseInt(json['id']),
      amount: _parseDouble(json['amount']),
      status: json['status'] ?? 'pending',
      bankName: json['bank_name'],
      accountLast4: json['account_last_4'],
      requestedAt: json['requested_at'] != null 
          ? (DateTime.tryParse(json['requested_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'].toString())
          : null,
    );
  }
}
