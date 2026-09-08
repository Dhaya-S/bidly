import 'package:intl/intl.dart';

class ListingModel {
  final String id;
  final String title;
  final String? description;
  final double price;
  final String? primaryImageUrl;
  final String? reelUrl;
  final String? city;
  final String? state;
  final String? locality;
  final String condition;
  final String sellingMethod; // DIRECT_BUY, AUCTION
  final double? startingBid;
  final double? currentBid;
  final DateTime? auctionEndTime;
  final double rating;
  final double distanceKm;
  final bool isWishlisted;
  final String? sellerName;
  final String? sellerId;
  final String? categoryName;
  final List<String> imageUrls;
  final String? subcategory;
  final String? purchaseDate;
  final bool hasDamage;
  final String? damageDetails;
  final String? communityName;
  final int likesCount;
  final int bidsCount;
  final bool isLikedByMe;
  final List<MediaItemModel> mediaItems;

  const ListingModel({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    this.primaryImageUrl,
    this.imageUrls = const [],
    this.mediaItems = const [],
    this.reelUrl,
    this.city,
    this.state,
    this.locality,
    this.condition = 'USED',
    this.sellingMethod = 'DIRECT_BUY',
    this.startingBid,
    this.currentBid,
    this.auctionEndTime,
    this.rating = 4.5,
    this.distanceKm = 0.0,
    this.isWishlisted = false,
    this.isLikedByMe = false,
    this.sellerName,
    this.sellerId,
    this.categoryName,
    this.subcategory,
    this.purchaseDate,
    this.hasDamage = false,
    this.damageDetails,
    this.communityName,
    this.likesCount = 0,
    this.bidsCount = 0,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['imageUrls'] is List) {
      images = (json['imageUrls'] as List).map((e) => e.toString()).toList();
    } else if (json['primaryImageUrl'] != null && json['primaryImageUrl'].toString().isNotEmpty) {
      images = [json['primaryImageUrl'].toString()];
    }

    List<MediaItemModel> parsedMediaItems = [];
    if (json['mediaItems'] is List && (json['mediaItems'] as List).isNotEmpty) {
      parsedMediaItems = (json['mediaItems'] as List)
          .map((m) => MediaItemModel.fromJson(m as Map<String, dynamic>))
          .toList();
    } else {
      // Fallback: construct from images + reelUrl
      for (int i = 0; i < images.length; i++) {
        parsedMediaItems.add(MediaItemModel(url: images[i], type: 'IMAGE', sortOrder: i));
      }
      final reel = json['reelUrl'] as String?;
      if (reel != null && reel.trim().isNotEmpty) {
        parsedMediaItems.add(MediaItemModel(url: reel, type: 'VIDEO', sortOrder: parsedMediaItems.length));
      }
    }

    return ListingModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      primaryImageUrl: json['primaryImageUrl'] as String?,
      imageUrls: images,
      mediaItems: parsedMediaItems,
      reelUrl: json['reelUrl'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      locality: json['locality'] as String?,
      condition: json['condition'] as String? ?? 'USED',
      sellingMethod: json['sellingMethod'] as String? ?? 'DIRECT_BUY',
      startingBid: (json['startingBid'] as num?)?.toDouble(),
      currentBid: (json['currentBid'] as num?)?.toDouble(),
      auctionEndTime: json['auctionEndTime'] != null
          ? DateTime.tryParse(json['auctionEndTime'].toString())
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      isWishlisted: json['wishlisted'] as bool? ?? false,
      isLikedByMe: json['isLikedByMe'] as bool? ?? json['likedByMe'] as bool? ?? false,
      sellerName: json['sellerName'] as String?,
      sellerId: json['sellerId'] as String?,
      categoryName: json['categoryName'] as String?,
      subcategory: json['subcategory'] as String?,
      purchaseDate: json['purchaseDate'] as String?,
      hasDamage: json['hasDamage'] as bool? ?? false,
      damageDetails: json['damageDetails'] as String?,
      communityName: json['communityName'] as String?,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      bidsCount: (json['bidsCount'] as num?)?.toInt() ?? 0,
    );
  }

  ListingModel copyWith({
    bool? isWishlisted,
    bool? isLikedByMe,
    int? likesCount,
  }) {
    return ListingModel(
      id: id,
      title: title,
      description: description,
      price: price,
      primaryImageUrl: primaryImageUrl,
      imageUrls: imageUrls,
      mediaItems: mediaItems,
      reelUrl: reelUrl,
      city: city,
      state: state,
      locality: locality,
      condition: condition,
      sellingMethod: sellingMethod,
      startingBid: startingBid,
      currentBid: currentBid,
      auctionEndTime: auctionEndTime,
      rating: rating,
      distanceKm: distanceKm,
      isWishlisted: isWishlisted ?? this.isWishlisted,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      sellerName: sellerName,
      sellerId: sellerId,
      categoryName: categoryName,
      subcategory: subcategory,
      purchaseDate: purchaseDate,
      hasDamage: hasDamage,
      damageDetails: damageDetails,
      communityName: communityName,
      likesCount: likesCount ?? this.likesCount,
      bidsCount: bidsCount,
    );
  }

  bool get isAuction => sellingMethod.toUpperCase() == 'AUCTION';

  String get formattedPrice {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return format.format(isAuction ? (currentBid ?? price) : price);
  }

  String get formattedDistance {
    if (distanceKm <= 0) {
      return locality ?? city ?? 'Local';
    }
    if (distanceKm < 0.1) return '< 0.1 km';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get formattedLocation {
    final loc = locality?.trim().isNotEmpty == true
        ? locality!.trim()
        : (city?.trim().isNotEmpty == true ? city!.trim() : null);
    if (distanceKm > 0) {
      final distStr = distanceKm < 0.1 ? '< 0.1 km' : '${distanceKm.toStringAsFixed(1)} km';
      if (loc != null) {
        return '$loc, $distStr';
      }
      return distStr;
    }
    if (loc != null) return loc;
    return 'Local';
  }

  String get formattedCondition {
    switch (condition.toUpperCase()) {
      case 'LIKE_NEW':
        return 'Like New';
      case 'GOOD':
        return 'Good';
      case 'NEW':
        return 'New';
      case 'REFURBISHED':
        return 'Refurbished';
      default:
        return 'Used';
    }
  }

  String get timeLeft {
    if (auctionEndTime == null) return '2h 35m';
    final diff = auctionEndTime!.difference(DateTime.now());
    if (diff.isNegative) return 'Ended';
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    return '${diff.inMinutes}m';
  }
}

class MediaItemModel {
  final String url;
  final String type; // 'IMAGE' or 'VIDEO'
  final int sortOrder;

  const MediaItemModel({
    required this.url,
    this.type = 'IMAGE',
    this.sortOrder = 0,
  });

  bool get isVideo => type.toUpperCase() == 'VIDEO';
  bool get isImage => !isVideo;

  factory MediaItemModel.fromJson(Map<String, dynamic> json) {
    return MediaItemModel(
      url: json['url'] as String? ?? '',
      type: json['type'] as String? ?? 'IMAGE',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
