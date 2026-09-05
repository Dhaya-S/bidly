class OfferModel {
  final String id;
  final String listingId;
  final String? listingTitle;
  final double listingPrice;
  final String? listingImageUrl;

  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;

  final double amount;
  final double? counterAmount;
  final String status; // PENDING, ACCEPTED, REJECTED, COUNTERED, CANCELLED, EXPIRED
  final String? message;

  final bool isBuyer;
  final bool isSeller;

  final String? orderId;
  final String? meetupLocation;
  final DateTime? meetupTime;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const OfferModel({
    required this.id,
    required this.listingId,
    this.listingTitle,
    this.listingPrice = 0.0,
    this.listingImageUrl,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.amount,
    this.counterAmount,
    required this.status,
    this.message,
    this.isBuyer = false,
    this.isSeller = false,
    this.orderId,
    this.meetupLocation,
    this.meetupTime,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isPending => status == 'PENDING';
  bool get isCountered => status == 'COUNTERED';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isRejected => status == 'REJECTED';
  bool get isCancelled => status == 'CANCELLED';

  double get currentEffectiveAmount => counterAmount != null && counterAmount! > 0 ? counterAmount! : amount;

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty) return null;
    if (str.contains('T') || (str.length >= 19 && str[10] == ' ')) {
      final isoStr = str.contains('T') ? str : str.replaceFirst(' ', 'T');
      final hasTz = isoStr.endsWith('Z') || isoStr.contains('+') || RegExp(r'-\d{2}:\d{2}$').hasMatch(isoStr);
      final normalized = hasTz ? isoStr : '${isoStr}Z';
      final dt = DateTime.tryParse(normalized);
      if (dt != null) return dt.toLocal();
    }
    final dt = DateTime.tryParse(str);
    return dt?.isUtc == true ? dt?.toLocal() : dt;
  }

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id']?.toString() ?? '',
      listingId: json['listingId']?.toString() ?? '',
      listingTitle: json['listingTitle']?.toString(),
      listingPrice: (json['listingPrice'] is num) ? (json['listingPrice'] as num).toDouble() : 0.0,
      listingImageUrl: json['listingImageUrl']?.toString(),
      buyerId: json['buyerId']?.toString() ?? '',
      buyerName: json['buyerName']?.toString() ?? 'Buyer',
      sellerId: json['sellerId']?.toString() ?? '',
      sellerName: json['sellerName']?.toString() ?? 'Seller',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      counterAmount: (json['counterAmount'] is num) ? (json['counterAmount'] as num).toDouble() : null,
      status: json['status']?.toString() ?? 'PENDING',
      message: json['message']?.toString(),
      isBuyer: json['buyer'] == true || json['isBuyer'] == true,
      isSeller: json['seller'] == true || json['isSeller'] == true,
      orderId: json['orderId']?.toString(),
      meetupLocation: json['meetupLocation']?.toString(),
      meetupTime: _parseDate(json['meetupTime']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      expiresAt: _parseDate(json['expiresAt']),
    );
  }
}
