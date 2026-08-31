import 'chat_message_model.dart';

class ChatEventModel {
  final String eventType;
  final String? roomId;
  final String? userId;
  final String? userName;
  final ChatMessageModel? message;
  final List<String> readMessageIds;
  final DateTime? readAt;
  final String? offerId;
  final String? offerStatus;
  final double? offerAmount;
  final double? counterAmount;
  final String? meetupStatus;
  final String? meetupLocation;
  final DateTime? meetupTime;
  final bool? isOnline;
  final DateTime? lastSeen;
  final DateTime timestamp;

  ChatEventModel({
    required this.eventType,
    this.roomId,
    this.userId,
    this.userName,
    this.message,
    this.readMessageIds = const [],
    this.readAt,
    this.offerId,
    this.offerStatus,
    this.offerAmount,
    this.counterAmount,
    this.meetupStatus,
    this.meetupLocation,
    this.meetupTime,
    this.isOnline,
    this.lastSeen,
    required this.timestamp,
  });

  factory ChatEventModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final rawMsg = json['message'] as Map<String, dynamic>?;
    final rawReadIds = json['readMessageIds'] as List?;

    return ChatEventModel(
      eventType: json['eventType'] as String? ?? 'NEW_MESSAGE',
      roomId: json['roomId'] as String?,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      message: rawMsg != null ? ChatMessageModel.fromJson(rawMsg, currentUserId: currentUserId) : null,
      readMessageIds: rawReadIds != null ? rawReadIds.map((e) => e.toString()).toList() : [],
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'].toString()) : null,
      offerId: json['offerId'] as String?,
      offerStatus: json['offerStatus'] as String?,
      offerAmount: (json['offerAmount'] as num?)?.toDouble(),
      counterAmount: (json['counterAmount'] as num?)?.toDouble(),
      meetupStatus: json['meetupStatus'] as String?,
      meetupLocation: json['meetupLocation'] as String?,
      meetupTime: json['meetupTime'] != null ? DateTime.tryParse(json['meetupTime'].toString()) : null,
      isOnline: json['online'] as bool?,
      lastSeen: json['lastSeen'] != null ? DateTime.tryParse(json['lastSeen'].toString()) : null,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
