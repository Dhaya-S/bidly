import 'package:intl/intl.dart';

class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String? senderName;
  final String? clientMessageId;
  final String? content;
  final double? offerAmount;
  final String type; // TEXT, IMAGE, SYSTEM, OFFER, OFFER_ACCEPTED, OFFER_REJECTED, OFFER_COUNTERED, MEETUP_REQUEST, MEETUP_ACCEPTED, MEETUP_REJECTED, ORDER_UPDATE, DELIVERY_UPDATE, QUICK_REPLY
  final String status; // SENDING, SENT, DELIVERED, READ, FAILED
  final DateTime? readAt;
  final String? mediaUrl;
  final String? metadata;
  final bool isMine;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.senderName,
    this.clientMessageId,
    this.content,
    this.offerAmount,
    this.type = 'TEXT',
    this.status = 'SENT',
    this.readAt,
    this.mediaUrl,
    this.metadata,
    this.isMine = false,
    required this.createdAt,
  });

  bool get isOffer => type.toUpperCase().startsWith('OFFER');
  bool get isQuickReply => type.toUpperCase() == 'QUICK_REPLY';
  bool get isMeetup => type.toUpperCase().startsWith('MEETUP');
  bool get isSystem => type.toUpperCase() == 'SYSTEM' || type.toUpperCase().contains('UPDATE');
  bool get isImage => type.toUpperCase() == 'IMAGE';
  bool get isSending => status.toUpperCase() == 'SENDING';
  bool get isFailed => status.toUpperCase() == 'FAILED';
  bool get isRead => status.toUpperCase() == 'READ' || readAt != null;

  ChatMessageModel copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? senderName,
    String? clientMessageId,
    String? content,
    double? offerAmount,
    String? type,
    String? status,
    DateTime? readAt,
    String? mediaUrl,
    String? metadata,
    bool? isMine,
    DateTime? createdAt,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      content: content ?? this.content,
      offerAmount: offerAmount ?? this.offerAmount,
      type: type ?? this.type,
      status: status ?? this.status,
      readAt: readAt ?? this.readAt,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      metadata: metadata ?? this.metadata,
      isMine: isMine ?? this.isMine,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final senderId = json['senderId'] as String? ?? '';
    final isMine = (json['mine'] == true) || (currentUserId != null && senderId == currentUserId);
    return ChatMessageModel(
      id: json['id'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      senderId: senderId,
      senderName: json['senderName'] as String?,
      clientMessageId: json['clientMessageId'] as String?,
      content: json['content'] as String?,
      offerAmount: (json['offerAmount'] as num?)?.toDouble(),
      type: json['type'] as String? ?? 'TEXT',
      status: json['status'] as String? ?? 'SENT',
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'].toString()) : null,
      mediaUrl: json['mediaUrl'] as String?,
      metadata: json['metadata'] as String?,
      isMine: isMine,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get formattedTime {
    return DateFormat('h:mm a').format(createdAt);
  }

  String get formattedDateHeader {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (msgDate == today) {
      return 'TODAY';
    } else if (msgDate == yesterday) {
      return 'YESTERDAY';
    } else if (now.year == createdAt.year) {
      return DateFormat('d MMM').format(createdAt).toUpperCase();
    } else {
      return DateFormat('d MMM yyyy').format(createdAt).toUpperCase();
    }
  }

  bool isSameDay(ChatMessageModel other) {
    return createdAt.year == other.createdAt.year &&
        createdAt.month == other.createdAt.month &&
        createdAt.day == other.createdAt.day;
  }
}
