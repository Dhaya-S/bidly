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
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserRole;
  final String status;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final String? lastMessagePreview;
  final bool isOnline;
  final DateTime? lastSeen;

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
    this.otherUserId,
    this.otherUserName,
    this.otherUserRole,
    this.status = 'OPEN',
    this.unreadCount = 0,
    this.lastMessageAt,
    this.createdAt,
    this.lastMessagePreview,
    this.isOnline = false,
    this.lastSeen,
  });

  ChatRoomModel copyWith({
    String? id,
    String? listingId,
    String? listingTitle,
    String? listingImageUrl,
    double? listingPrice,
    String? buyerId,
    String? buyerName,
    String? sellerId,
    String? sellerName,
    String? otherUserId,
    String? otherUserName,
    String? otherUserRole,
    String? status,
    int? unreadCount,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    String? lastMessagePreview,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      listingImageUrl: listingImageUrl ?? this.listingImageUrl,
      listingPrice: listingPrice ?? this.listingPrice,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserRole: otherUserRole ?? this.otherUserRole,
      status: status ?? this.status,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

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
      otherUserId: json['otherUserId'] as String?,
      otherUserName: json['otherUserName'] as String?,
      otherUserRole: json['otherUserRole'] as String?,
      status: json['status'] as String? ?? 'OPEN',
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      lastMessagePreview: json['lastMessagePreview'] as String?,
      isOnline: json['online'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
    );
  }
}
