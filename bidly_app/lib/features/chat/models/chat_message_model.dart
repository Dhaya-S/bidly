import 'dart:convert';
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
  final String? localPath;
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
    this.localPath,
    this.metadata,
    this.isMine = false,
    required this.createdAt,
  });

  bool get isOffer => type.toUpperCase() == 'OFFER' || type.toUpperCase() == 'OFFER_PENDING';
  bool get isOfferAccepted => type.toUpperCase() == 'OFFER_ACCEPTED';
  bool get isOfferCountered => type.toUpperCase() == 'OFFER_COUNTERED';
  bool get isMeetup => type.toUpperCase() == 'MEETUP_REQUEST' || type.toUpperCase() == 'MEETUP';
  bool get isMeetupRequest => type.toUpperCase() == 'MEETUP_REQUEST';
  bool get isMeetupAccepted => type.toUpperCase() == 'MEETUP_ACCEPTED';
  bool get isQuickReply => type.toUpperCase() == 'QUICK_REPLY';
  bool get isSystem => type.toUpperCase() == 'SYSTEM' || type.toUpperCase().contains('UPDATE');
  bool get isImage => type.toUpperCase() == 'IMAGE';
  bool get isSending => status.toUpperCase() == 'SENDING';
  bool get isFailed => status.toUpperCase() == 'FAILED';
  bool get isRead => status.toUpperCase() == 'READ' || readAt != null;

  bool get isShipmentDispatched {
    if (metadata != null && metadata!.contains('trackingNumber')) return true;
    if (content != null && content!.toLowerCase().contains('shipment dispatched')) return true;
    return false;
  }

  bool get isDeliveryAddressShared {
    if (metadata != null && (metadata!.contains('DELIVERY_ADDRESS_SHARED') || metadata!.contains('recipientName'))) return true;
    if (content != null && content!.toLowerCase().startsWith('delivery address:')) return true;
    return false;
  }

  bool get isTransactionCompleted {
    if (type.toUpperCase() == 'TRANSACTION_COMPLETED') return true;
    if (content != null && (content!.toLowerCase().contains('delivery confirmed') || content!.toLowerCase().contains('transaction is completed'))) return true;
    return false;
  }

  Map<String, dynamic>? get parsedMetadata {
    if (metadata == null || metadata!.isEmpty) return null;
    try {
      return jsonDecode(metadata!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

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
    String? localPath,
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
      localPath: localPath ?? this.localPath,
      metadata: metadata ?? this.metadata,
      isMine: isMine ?? this.isMine,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime _parseDateTime(dynamic raw, {DateTime? fallback}) {
    if (raw == null) return fallback ?? DateTime.now();
    if (raw is List && raw.length >= 3) {
      final y = (raw[0] as num).toInt();
      final m = (raw[1] as num).toInt();
      final d = (raw[2] as num).toInt();
      final h = raw.length > 3 ? (raw[3] as num).toInt() : 0;
      final min = raw.length > 4 ? (raw[4] as num).toInt() : 0;
      final s = raw.length > 5 ? (raw[5] as num).toInt() : 0;
      final ms = raw.length > 6 ? ((raw[6] as num).toInt() ~/ 1000000) : 0;
      return DateTime.utc(y, m, d, h, min, s, ms).toLocal();
    }
    if (raw is int) {
      return (raw < 10000000000)
          ? DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true).toLocal()
          : DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true).toLocal();
    }
    if (raw is double) {
      return DateTime.fromMillisecondsSinceEpoch((raw * 1000).toInt(), isUtc: true).toLocal();
    }
    final str = raw.toString().trim();
    if (str.isEmpty) return fallback ?? DateTime.now();
    final asInt = int.tryParse(str);
    if (asInt != null) {
      return (asInt < 10000000000)
          ? DateTime.fromMillisecondsSinceEpoch(asInt * 1000, isUtc: true).toLocal()
          : DateTime.fromMillisecondsSinceEpoch(asInt, isUtc: true).toLocal();
    }
    final asDouble = double.tryParse(str);
    if (asDouble != null) {
      return DateTime.fromMillisecondsSinceEpoch((asDouble * 1000).toInt(), isUtc: true).toLocal();
    }
    if (str.contains('T') || (str.length >= 19 && str[10] == ' ')) {
      final isoStr = str.contains('T') ? str : str.replaceFirst(' ', 'T');
      final hasTz = isoStr.endsWith('Z') || isoStr.contains('+') || RegExp(r'-\d{2}:\d{2}$').hasMatch(isoStr);
      final normalized = hasTz ? isoStr : '${isoStr}Z';
      final dt = DateTime.tryParse(normalized);
      if (dt != null) return dt.toLocal();
    }
    final dt = DateTime.tryParse(str);
    if (dt != null) {
      return dt.isUtc ? dt.toLocal() : dt;
    }
    return fallback ?? DateTime.now();
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
      readAt: json['readAt'] != null ? _parseDateTime(json['readAt'], fallback: null) : null,
      mediaUrl: json['mediaUrl'] as String?,
      metadata: json['metadata'] as String?,
      isMine: isMine,
      createdAt: _parseDateTime(json['createdAt']),
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
