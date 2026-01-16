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

/// User Model
class User {
  final int id;
  final String userType;
  final String phone;
  final String name;
  final int? age;
  final String? bio;
  final String? avatar;
  final String? location;
  final String status;
  final String accountStatus;
  final bool isVerified;
  final bool isInChat;
  final String? voiceStatus;
  final String? voiceVerificationUrl;

  // Male specific
  final int? coinBalance;
  final int? totalCoinsPurchased;
  final int? totalCoinsSpent;

  // Female specific
  final double? earningBalance;
  final double? totalEarned;
  final double? totalWithdrawn;
  final double? ratePerMinute;
  final bool? hasBankDetails;

  User({
    required this.id,
    required this.userType,
    required this.phone,
    required this.name,
    this.age,
    this.bio,
    this.avatar,
    this.location,
    required this.status,
    required this.accountStatus,
    required this.isVerified,
    required this.isInChat,
    this.voiceStatus,
    this.voiceVerificationUrl,
    this.coinBalance,
    this.totalCoinsPurchased,
    this.totalCoinsSpent,
    this.earningBalance,
    this.totalEarned,
    this.totalWithdrawn,
    this.ratePerMinute,
    this.hasBankDetails,
  });

  bool get isMale => userType == 'male';
  bool get isFemale => userType == 'female';
  bool get isOnline => status == 'online';
  bool get isBusy => status == 'busy';
  bool get isAvailable => status == 'online' && accountStatus == 'active';

  factory User.fromJson(Map<String, dynamic> json) {
    final id = _parseInt(json['id']);
    return User(
      id: id,
      userType: json['user_type'] ?? 'male',
      phone: json['phone'] ?? '',
      name: json['name'] ?? 'User #$id',
      age: json['age'] != null ? _parseInt(json['age']) : null,
      bio: json['bio'],
      avatar: json['avatar'],
      location: json['location'],
      status: json['status'] ?? 'offline',
      accountStatus: json['account_status'] ?? 'pending',
      isVerified: json['is_verified'] ?? false,
      isInChat: json['is_in_chat'] ?? false,
      voiceStatus: json['voice_status'],
      voiceVerificationUrl: json['voice_verification_url'],
      coinBalance: _parseInt(json['coin_balance']),
      totalCoinsPurchased: _parseInt(json['total_coins_purchased']),
      totalCoinsSpent: _parseInt(json['total_coins_spent']),
      earningBalance: _parseDouble(json['earning_balance']),
      totalEarned: _parseDouble(json['total_earned']),
      totalWithdrawn: _parseDouble(json['total_withdrawn']),
      ratePerMinute: json['rate_per_minute'] != null ? _parseDouble(json['rate_per_minute']) : 10.0,
      hasBankDetails: json['has_bank_details'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_type': userType,
      'phone': phone,
      'name': name,
      'age': age,
      'bio': bio,
      'avatar': avatar,
      'location': location,
      'status': status,
      'account_status': accountStatus,
      'is_verified': isVerified,
      'is_in_chat': isInChat,
      'voice_status': voiceStatus,
      'voice_verification_url': voiceVerificationUrl,
      'coin_balance': coinBalance,
      'total_coins_purchased': totalCoinsPurchased,
      'total_coins_spent': totalCoinsSpent,
      'earning_balance': earningBalance,
      'total_earned': totalEarned,
      'total_withdrawn': totalWithdrawn,
      'rate_per_minute': ratePerMinute,
      'has_bank_details': hasBankDetails,
    };
  }
}

/// Female User for Male's Browse List
class FemaleUser {
  final int id;
  final String name;
  final int? age;
  final String? bio;
  final String? avatar;
  final String? location;
  final String status;
  final bool isAvailable;
  final double ratePerMinute;
  bool isLiked; // Track locally for now

  FemaleUser({
    required this.id,
    required this.name,
    this.age,
    this.bio,
    this.avatar,
    this.location,
    required this.status,
    required this.isAvailable,
    required this.ratePerMinute,
    this.isLiked = false,
  });

  factory FemaleUser.fromJson(Map<String, dynamic> json) {
    final id = _parseInt(json['id']);
    return FemaleUser(
      id: id,
      name: json['name'] ?? 'Female #$id',
      age: json['age'] != null ? _parseInt(json['age']) : null,
      bio: json['bio'],
      avatar: json['avatar'],
      location: json['location'],
      status: json['status'] ?? 'offline',
      isAvailable: json['is_available'] ?? false,
      ratePerMinute: _parseDouble(json['rate_per_minute'], 10.0),
      isLiked: json['is_liked'] ?? false,
    );
  }
}

/// Male User for Female's View (with potential earnings)
class MaleUser {
  final int id;
  final String status;
  final int coinBalance;
  final int possibleMinutes;
  final double potentialEarning;
  final String potentialEarningFormatted;

  MaleUser({
    required this.id,
    required this.status,
    required this.coinBalance,
    required this.possibleMinutes,
    required this.potentialEarning,
    required this.potentialEarningFormatted,
  });

  factory MaleUser.fromJson(Map<String, dynamic> json) {
    return MaleUser(
      id: _parseInt(json['id']),
      status: json['status'] ?? 'offline',
      coinBalance: _parseInt(json['coin_balance']),
      possibleMinutes: _parseInt(json['possible_minutes']),
      potentialEarning: _parseDouble(json['potential_earning']),
      potentialEarningFormatted: json['potential_earning_formatted'] ?? '₹0',
    );
  }
}
