class ChatRoomModel {
  final String id;
  final String listingId;
  final String? listingTitle;
  final String? listingImageUrl;
  final double listingPrice;
  final String buyerId;
  final String? buyerName;
  final String sellerId;
  final String? sellerName;
  final String status;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final String? lastMessagePreview;

  const ChatRoomModel({
    required this.id,
    required this.listingId,
    this.listingTitle,
    this.listingImageUrl,
    this.listingPrice = 0.0,
    required this.buyerId,
    this.buyerName,
    required this.sellerId,
    this.sellerName,
    this.status = 'OPEN',
    this.lastMessageAt,
    this.createdAt,
    this.lastMessagePreview,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] as String? ?? '',
      listingId: json['listingId'] as String? ?? '',
      listingTitle: json['listingTitle'] as String?,
      listingImageUrl: json['listingImageUrl'] as String?,
      listingPrice: (json['listingPrice'] as num?)?.toDouble() ?? 0.0,
      buyerId: json['buyerId'] as String? ?? '',
      buyerName: json['buyerName'] as String?,
      sellerId: json['sellerId'] as String? ?? '',
      sellerName: json['sellerName'] as String?,
      status: json['status'] as String? ?? 'OPEN',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      lastMessagePreview: json['lastMessagePreview'] as String?,
    );
  }
}
