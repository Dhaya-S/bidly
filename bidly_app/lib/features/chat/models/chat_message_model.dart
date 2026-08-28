class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String? senderName;
  final String? content;
  final double? offerAmount;
  final String type; // TEXT, OFFER, QUICK_REPLY
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.senderName,
    this.content,
    this.offerAmount,
    this.type = "TEXT",
    required this.createdAt,
  });

  bool get isOffer => type.toUpperCase() == "OFFER";
  bool get isQuickReply => type.toUpperCase() == "QUICK_REPLY";

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String?,
      content: json['content'] as String?,
      offerAmount: (json['offerAmount'] as num?)?.toDouble(),
      type: json['type'] as String? ?? 'TEXT',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
