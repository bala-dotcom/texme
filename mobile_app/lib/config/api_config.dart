/// API Configuration
class ApiConfig {
  ApiConfig._();

  // Base URL - Change for production
  // static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000/api'; // Chrome/Web testing
  static const String baseUrl = 'https://api.texme.online/api'; // Production

  // Endpoints - Auth
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String truecallerVerify = '/auth/truecaller-verify';
  static const String register = '/auth/register';
  static const String profile = '/auth/profile';
  static const String logout = '/auth/logout';

  // Endpoints - Users
  static const String listFemales = '/users/females';
  static const String listMales = '/users/males';
  static const String randomFemale = '/users/random';
  static const String userDetails = '/users'; // + /{id}
  static const String bankDetails = '/users/bank-details';

  // Endpoints - Chat
  static const String chatRequest = '/chat/request';
  static const String chatAccept = '/chat/accept'; // + /{id}
  static const String chatDecline = '/chat/decline'; // + /{id}
  static const String chatMessage = '/chat'; // + /{id}/message
  static const String chatVoice = '/chat'; // + /{id}/voice
  static const String chatEnd = '/chat'; // + /{id}/end
  static const String chatActive = '/chat/active';
  static const String chatPending = '/chat/pending';
  static const String chatHistory = '/chat/history';
  static const String chatMessages = '/chat'; // + /{id}/messages

  // Endpoints - Coins
  static const String coinBalance = '/coins/balance';
  static const String coinPackages = '/coins/packages';
  static const String coinPurchase = '/coins/purchase';
  static const String coinHistory = '/coins/history';

  // Endpoints - Wallet
  static const String walletBalance = '/wallet/balance';
  static const String walletHistory = '/wallet/history';
  static const String walletEarnings = '/wallet/earnings';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String walletWithdrawals = '/wallet/withdrawals';

  // Endpoints - Others
  static const String reportUser = '/report/user';
  static const String reportMessage = '/report/message';
  static const String appSettings = '/settings/app';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

/// Pusher Configuration
class PusherConfig {
  PusherConfig._();

  static const String appKey = 'YOUR_PUSHER_KEY'; // Replace with actual key
  static const String cluster = 'ap2';

  // Channels
  static String userChannel(int userId) => 'private-user.$userId';
  static String chatChannel(int chatId) => 'private-chat.$chatId';

  // Events
  static const String chatRequest = 'chat.request';
  static const String chatAccepted = 'chat.accepted';
  static const String chatDeclined = 'chat.declined';
  static const String chatMessage = 'chat.message';
  static const String chatEnded = 'chat.ended';
  static const String coinsUpdated = 'coins.updated';
  static const String earningsUpdated = 'earnings.updated';
}

/// App Config
class AppConfig {
  AppConfig._();

  static const String appName = 'Texme';
  static const String appVersion = '1.0.0';
  static const String appPackage = 'com.texme.texme';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String userTypeKey = 'user_type';

  // MSG91 SendOTP Configuration
  static const String msg91WidgetId = '366168747878333233323639';
  static const String msg91AuthToken = '487192TsQlWeZ2ff69601763P1';
}
