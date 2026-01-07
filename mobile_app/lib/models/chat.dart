import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

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

/// Chat Model
class Chat {
  final int id;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int totalMinutes;
  final int coinsSpent;
  final double femaleEarnings;
  final ChatPartner? partner;

  Chat({
    required this.id,
    required this.status,
    this.startedAt,
    this.endedAt,
    required this.totalMinutes,
    required this.coinsSpent,
    required this.femaleEarnings,
    this.partner,
  });

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isEnded => status == 'ended';

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: _parseInt(json['id']),
      status: json['status'] ?? 'pending',
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at']?.toString() ?? '')
          : null,
      endedAt: json['ended_at'] != null 
          ? DateTime.tryParse(json['ended_at']?.toString() ?? '') 
          : null,
      totalMinutes: _parseInt(json['total_minutes']),
      coinsSpent: _parseInt(json['coins_spent']),
      femaleEarnings: _parseDouble(json['female_earnings']),
      partner: json['partner'] != null
          ? ChatPartner.fromJson(json['partner'])
          : null,
    );
  }
}

/// Chat Partner
class ChatPartner {
  final int id;
  final String name;
  final String? avatar;

  ChatPartner({
    required this.id,
    required this.name,
    this.avatar,
  });

  factory ChatPartner.fromJson(Map<String, dynamic> json) {
    final id = _parseInt(json['id']);
    return ChatPartner(
      id: id,
      name: json['name'] ?? 'User #$id',
      avatar: json['avatar'],
    );
  }
}

/// Chat Request (Incoming)
class ChatRequest {
  final int chatId;
  final int maleId;
  final String maleName;
  final String? maleAvatar;
  final double potentialEarning;
  final String potentialEarningFormatted;
  final DateTime requestedAt;

  ChatRequest({
    required this.chatId,
    required this.maleId,
    required this.maleName,
    this.maleAvatar,
    required this.potentialEarning,
    required this.potentialEarningFormatted,
    required this.requestedAt,
  });

  factory ChatRequest.fromJson(Map<String, dynamic> json) {
    final maleId = _parseInt(json['male_id']);
    final chatId = _parseInt(json['chat_id']);
    return ChatRequest(
      chatId: chatId,
      maleId: maleId,
      maleName: json['male_name'] ?? 'User #$maleId',
      maleAvatar: json['male_avatar'],
      potentialEarning: _parseDouble(json['potential_earning']),
      potentialEarningFormatted: json['potential_earning_formatted'] ?? '₹0',
      requestedAt: json['requested_at'] != null 
          ? DateTime.tryParse(json['requested_at']?.toString() ?? '') ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Message Model
class Message {
  final int id;
  final int senderId;
  final String type;
  final String? content;
  final String? voiceUrl;
  final int? voiceDuration;
  final String status;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.type,
    this.content,
    this.voiceUrl,
    this.voiceDuration,
    required this.status,
    required this.createdAt,
  });

  bool get isText => type == 'text';
  bool get isVoice => type == 'voice';
  bool get isSent => status == 'sent';
  bool get isDelivered => status == 'delivered';
  bool get isSending => status == 'sending';
  bool get isFailed => status == 'failed';

  factory Message.optimistic({
    required int senderId,
    String? content,
    String type = 'text',
    String? voiceUrl,
    int? voiceDuration,
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch,
      senderId: senderId,
      type: type,
      content: content,
      voiceUrl: voiceUrl,
      voiceDuration: voiceDuration,
      status: 'sending',
      createdAt: DateTime.now(),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    // Parse created_at with fallback
    DateTime createdAt;
    try {
      if (json['created_at'] != null) {
        createdAt = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }
    
    // Fix voice URL if it contains localhost or 10.0.2.2 (for real devices)
    String? voiceUrl = json['voice_url'];
    if (voiceUrl != null) {
      try {
        final baseUri = Uri.parse(ApiConfig.baseUrl);
        final host = baseUri.host;
        
        if (voiceUrl.contains('localhost') || voiceUrl.contains('127.0.0.1') || voiceUrl.contains('10.0.2.2')) {
          voiceUrl = voiceUrl.replaceAll('localhost', host)
                             .replaceAll('127.0.0.1', host)
                             .replaceAll('10.0.2.2', host);
        }
      } catch (e) {
        debugPrint('⚠️ Error fixing voice URL: $e');
      }
    }
    
    return Message(
      id: _parseInt(json['id']),
      senderId: _parseInt(json['sender_id']),
      type: json['type'] ?? 'text',
      content: json['content'],
      voiceUrl: voiceUrl,
      voiceDuration: json['voice_duration'] != null ? _parseInt(json['voice_duration']) : null,
      status: json['status'] ?? 'sent',
      createdAt: createdAt,
    );
  }
}
