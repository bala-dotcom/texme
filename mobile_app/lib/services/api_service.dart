import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// API Service for making HTTP requests
class ApiService {
  static ApiService? _instance;
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectionTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if available
        final token = await _storage.read(key: AppConfig.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle 401 - unauthorized
        if (error.response?.statusCode == 401) {
          // Token expired, logout user
          _storage.deleteAll();
        }
        return handler.next(error);
      },
    ));
  }

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  // ========== AUTH ENDPOINTS ==========

  Future<ApiResponse> sendOtp(String phone) async {
    try {
      final response = await _dio.post(ApiConfig.sendOtp, data: {
        'phone': phone,
      });
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> verifyOtp({String? phone, String? otp, String? accessToken}) async {
    try {
      final response = await _dio.post(ApiConfig.verifyOtp, data: {
        if (phone != null) 'phone': phone,
        if (otp != null) 'otp': otp,
        if (accessToken != null) 'access_token': accessToken,
      });
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> register({
    required String registrationToken,
    required String userType,
    String? name,
    int? age,
    String? bio,
    File? avatar,
    String? avatarUrl,
    File? voiceVerification,
  }) async {
    try {
      print('DEBUG: Starting registration for $userType');
      print('DEBUG: Token length: ${registrationToken.length}');
      
      // Use FormData when we have file uploads (voice verification)
      if (voiceVerification != null) {
        FormData formData = FormData.fromMap({
          'registration_token': registrationToken,
          'user_type': userType,
          if (name != null) 'name': name,
          if (age != null) 'age': age,
          if (bio != null) 'bio': bio,
          if (avatarUrl != null) 'avatar': avatarUrl,
          'voice_verification': await MultipartFile.fromFile(
            voiceVerification.path,
            filename: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
          ),
        });

        print('DEBUG: Sending registration with voice file');
        final response = await _dio.post(ApiConfig.register, data: formData);
        print('DEBUG: Registration response: ${response.data}');
        return ApiResponse.success(response.data);
      } else {
        // Use JSON with avatar URL (no file uploads)
        Map<String, dynamic> data = {
          'registration_token': registrationToken,
          'user_type': userType,
          if (name != null) 'name': name,
          if (age != null) 'age': age,
          if (bio != null) 'bio': bio,
          if (avatarUrl != null) 'avatar': avatarUrl,
        };

        print('DEBUG: Sending registration request with data: $data');
        final response = await _dio.post(ApiConfig.register, data: data);
        print('DEBUG: Registration response: ${response.data}');
        return ApiResponse.success(response.data);
      }
    } catch (e) {
      print('DEBUG: Registration error: $e');
      return _handleError(e);
    }
  }

  Future<ApiResponse> getProfile() async {
    try {
      final response = await _dio.get(ApiConfig.profile);
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> updateProfile({
    String? name,
    int? age,
    String? bio,
    String? location,
    File? avatar,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        if (name != null) 'name': name,
        if (age != null) 'age': age,
        if (bio != null) 'bio': bio,
        if (location != null) 'location': location,
        if (avatar != null)
          'avatar': await MultipartFile.fromFile(avatar.path),
      });

      final response = await _dio.put(ApiConfig.profile, data: formData);
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> updateOnlineStatus(bool isOnline) async {
    try {
      final response = await _dio.post('/auth/online-status', data: {
        'is_online': isOnline,
      });
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> updateFcmToken(String fcmToken) async {
    try {
      final response = await _dio.post('/auth/fcm-token', data: {
        'fcm_token': fcmToken,
      });
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> logout() async {
    try {
      final response = await _dio.post(ApiConfig.logout);
      await _storage.deleteAll();
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ========== USER ENDPOINTS ==========

  Future<ApiResponse> getFemales({int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConfig.listFemales,
        queryParameters: {'page': page},
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> getMales({int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConfig.listMales,
        queryParameters: {'page': page},
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> getRandomFemale() async {
    try {
      final response = await _dio.get(ApiConfig.randomFemale);
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> updateBankDetails({
    required String accountName,
    required String accountNumber,
    required String ifsc,
    required String bankName,
    String? upiId,
  }) async {
    try {
      final response = await _dio.post(ApiConfig.bankDetails, data: {
        'account_name': accountName,
        'account_number': accountNumber,
        'ifsc': ifsc,
        'bank_name': bankName,
        if (upiId != null) 'upi_id': upiId,
      });
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> getBankDetails() async {
    try {
      final response = await _dio.get(ApiConfig.bankDetails);
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ========== CHAT ENDPOINTS ==========

  Future<ApiResponse> sendChatRequest(int femaleId) async {
    try {
      final response = await _dio.post(ApiConfig.chatRequest, data: {
        'female_id': femaleId,
      });
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> acceptChat(int chatId) async {
    try {
      final response = await _dio.post('${ApiConfig.chatAccept}/$chatId');
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> declineChat(int chatId) async {
    try {
      final response = await _dio.post('${ApiConfig.chatDecline}/$chatId');
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> getChatStatus(int chatId) async {
    try {
      final response = await _dio.get('/chat/$chatId/status');
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> cancelChatRequest(int chatId) async {
    try {
      final response = await _dio.post('/chat/$chatId/cancel');
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> sendMessage(int chatId, String content) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.chatMessage}/$chatId/message',
        data: {'content': content},
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> chargeMinute(int chatId) async {
    try {
      final response = await _dio.post('/chat/$chatId/charge');
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> sendVoiceMessage(
      int chatId, File voiceFile, int duration) async {
    try {
      // Get file extension and set proper content type
      final fileName = voiceFile.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      
      // Map extension to MIME type
      String contentType;
      switch (extension) {
        case 'mp3':
          contentType = 'audio/mpeg';
          break;
        case 'wav':
          contentType = 'audio/wav';
          break;
        case 'm4a':
          contentType = 'audio/mp4';
          break;
        case 'ogg':
          contentType = 'audio/ogg';
          break;
        default:
          contentType = 'audio/mp4'; // Default to m4a format
      }
      
      FormData formData = FormData.fromMap({
        'voice': await MultipartFile.fromFile(
          voiceFile.path,
          filename: 'voice_message.$extension',
          contentType: DioMediaType.parse(contentType),
        ),
        'duration': duration,
      });

      final response = await _dio.post(
        '${ApiConfig.chatVoice}/$chatId/voice',
        data: formData,
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> setTypingStatus(int chatId) async {
    try {
      final response = await _dio.post('${ApiConfig.chatMessage}/$chatId/typing');
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> setRecordingStatus(int chatId) async {
    try {
      final response = await _dio.post('${ApiConfig.chatMessage}/$chatId/recording');
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> endChat(int chatId) async {
    try {
      final response = await _dio.post('${ApiConfig.chatEnd}/$chatId/end');
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> getActiveChat() async {
    try {
      final response = await _dio.get(ApiConfig.chatActive);
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> getPendingRequests() async {
    try {
      final response = await _dio.get(ApiConfig.chatPending);
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> getChatHistory({int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConfig.chatHistory,
        queryParameters: {'page': page},
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> getChatMessages(int chatId) async {
    try {
      final response =
          await _dio.get('${ApiConfig.chatMessages}/$chatId/messages');
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ========== COIN ENDPOINTS ==========

  Future<ApiResponse> getCoinBalance() async {
    try {
      final response = await _dio.get(ApiConfig.coinBalance);
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> getCoinPackages() async {
    try {
      final response = await _dio.get(ApiConfig.coinPackages);
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> initiateCoinPurchase(int packageIndex) async {
    try {
      final response = await _dio.post(ApiConfig.coinPurchase, data: {
        'package_index': packageIndex,
      });
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> purchaseCoins(int coins, double amount) async {
    try {
      final response = await _dio.post(ApiConfig.coinPurchase, data: {
        'coins': coins,
        'amount': amount,
      });
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Test mode: Add coins directly without payment (for testing/demo)
  Future<ApiResponse> testAddCoins(int coins) async {
    try {
      final response = await _dio.post('/coins/test-add', data: {
        'coins': coins,
      });
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> getCoinHistory({int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConfig.coinHistory,
        queryParameters: {'page': page},
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ========== WALLET ENDPOINTS ==========

  Future<ApiResponse> getWalletBalance() async {
    try {
      final response = await _dio.get(ApiConfig.walletBalance);
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> getWalletHistory({int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConfig.walletHistory,
        queryParameters: {'page': page},
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> requestWithdrawal(double amount) async {
    try {
      final response = await _dio.post(ApiConfig.walletWithdraw, data: {
        'amount': amount,
      });
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> getWithdrawalHistory({int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConfig.walletWithdrawals,
        queryParameters: {'page': page},
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ========== APP SETTINGS ==========

  Future<ApiResponse> getAppSettings() async {
    try {
      final response = await _dio.get(ApiConfig.appSettings);
      return ApiResponse.success(response.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ========== HELPER METHODS ==========

  ApiResponse _handleError(dynamic e) {
    if (e is DioException) {
      if (e.response != null) {
        final data = e.response?.data;
        final message = data is Map ? data['message'] : 'Request failed';
        return ApiResponse.error(message, e.response?.statusCode);
      } else if (e.type == DioExceptionType.connectionTimeout) {
        return ApiResponse.error('Connection timeout', null);
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return ApiResponse.error('Server not responding', null);
      } else {
        return ApiResponse.error('Network error', null);
      }
    }
    return ApiResponse.error('Unknown error occurred', null);
  }

  // Save auth token
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConfig.tokenKey, value: token);
  }

  // Get auth token
  Future<String?> getToken() async {
    return await _storage.read(key: AppConfig.tokenKey);
  }

  // Clear auth data
  Future<void> clearAuth() async {
    await _storage.deleteAll();
  }
}

/// API Response wrapper
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final int? statusCode;

  ApiResponse._({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(dynamic data) {
    return ApiResponse._(
      success: data['success'] ?? true,
      data: data,
      message: data['message'],
    );
  }

  factory ApiResponse.error(String message, int? statusCode) {
    return ApiResponse._(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}
