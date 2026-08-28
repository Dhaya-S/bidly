import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_theme.dart';
import '../../explore/models/listing_model.dart';

class PostModel {
  final String id;
  final String? authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String? communityId;
  final String? communityName;
  final String content;
  final String? mediaUrl;
  final String mediaType;
  final String tag; // SELLING, ANNOUNCEMENT, REVIEW, GENERAL
  final int likesCount;
  final int sharesCount;
  final bool isLikedByMe;
  final DateTime createdAt;

  // Instagram-style rich media items & optional linked listing details
  final List<MediaItemModel> mediaItems;
  final String? listingId;
  final String? sellingMethod;
  final double? price;
  final double? startingBid;
  final double? currentBid;
  final DateTime? auctionEndTime;
  final int bidsCount;

  const PostModel({
    required this.id,
    this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.communityId,
    this.communityName,
    required this.content,
    this.mediaUrl,
    this.mediaType = 'IMAGE',
    this.tag = 'SELLING',
    this.likesCount = 0,
    this.sharesCount = 0,
    this.isLikedByMe = false,
    required this.createdAt,
    this.mediaItems = const [],
    this.listingId,
    this.sellingMethod,
    this.price,
    this.startingBid,
    this.currentBid,
    this.auctionEndTime,
    this.bidsCount = 0,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    List<MediaItemModel> parsedMediaItems = [];
    if (json['mediaItems'] is List && (json['mediaItems'] as List).isNotEmpty) {
      parsedMediaItems = (json['mediaItems'] as List)
          .map((m) => MediaItemModel.fromJson(m as Map<String, dynamic>))
          .toList();
    } else if (json['mediaUrl'] != null && json['mediaUrl'].toString().trim().isNotEmpty) {
      final url = json['mediaUrl'].toString().trim();
      final type = json['mediaType'] as String? ?? 'IMAGE';
      parsedMediaItems = [MediaItemModel(url: url, type: type, sortOrder: 0)];
    }

    return PostModel(
      id: json['id'] as String? ?? '',
      authorId: json['authorId'] as String?,
      authorName: json['authorName'] as String? ?? 'Community Member',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      communityId: json['communityId'] as String?,
      communityName: json['communityName'] as String?,
      content: json['content'] as String? ?? '',
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: json['mediaType'] as String? ?? 'IMAGE',
      tag: json['tag'] as String? ?? 'SELLING',
      likesCount: json['likesCount'] as int? ?? 0,
      sharesCount: json['sharesCount'] as int? ?? 0,
      isLikedByMe: json['isLikedByMe'] as bool? ?? json['likedByMe'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      mediaItems: parsedMediaItems,
      listingId: json['listingId'] as String?,
      sellingMethod: json['sellingMethod'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      startingBid: (json['startingBid'] as num?)?.toDouble(),
      currentBid: (json['currentBid'] as num?)?.toDouble(),
      auctionEndTime: json['auctionEndTime'] != null
          ? DateTime.tryParse(json['auctionEndTime'].toString())
          : null,
      bidsCount: (json['bidsCount'] as num?)?.toInt() ?? 0,
    );
  }

  PostModel copyWith({
    int? likesCount,
    int? sharesCount,
    bool? isLikedByMe,
  }) {
    return PostModel(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      communityId: communityId,
      communityName: communityName,
      content: content,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      tag: tag,
      likesCount: likesCount ?? this.likesCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      createdAt: createdAt,
      mediaItems: mediaItems,
      listingId: listingId,
      sellingMethod: sellingMethod,
      price: price,
      startingBid: startingBid,
      currentBid: currentBid,
      auctionEndTime: auctionEndTime,
      bidsCount: bidsCount,
    );
  }

  bool get isAuction => sellingMethod?.toUpperCase() == 'AUCTION';

  String get formattedPrice {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    if (isAuction) {
      return format.format(currentBid ?? startingBid ?? price ?? 0);
    }
    return format.format(price ?? 0);
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get initials {
    final parts = authorName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return authorName.isNotEmpty ? authorName.substring(0, 1).toUpperCase() : 'U';
  }

  Color get tagColor {
    switch (tag.toUpperCase()) {
      case 'ANNOUNCEMENT':
        return const Color(0xFFE04F47);
      case 'REVIEW':
        return const Color(0xFF10B981);
      case 'SELLING':
      case 'DIRECT':
      case 'AUCTION':
      default:
        return AppTheme.primary;
    }
  }

  Color get avatarBgColor {
    if (tag.toUpperCase() == 'ANNOUNCEMENT') return const Color(0xFFE04F47);
    if (tag.toUpperCase() == 'REVIEW') return const Color(0xFFE89806);
    return AppTheme.primary;
  }
}
