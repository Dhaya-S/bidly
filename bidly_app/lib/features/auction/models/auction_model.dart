class AuctionDetailsModel {
  final String listingId;
  final String title;
  final String productCondition;
  final String? primaryImageUrl;
  final List<String> imageUrls;
  final double startingBid;
  final double currentHighestBid;
  final double minNextBid;
  final double minBidIncrement;
  final String? auctionEndTime;
  final int secondsRemaining;
  final String timeLeftFormatted;
  final int totalBids;
  final int watchingCount;
  final String? highestBidderId;
  final String highestBidderName;
  final String highestBidderTime;
  final String status;
  final bool isAuctionEnded;
  final bool isCurrentUserWinning;
  final double? currentUserBid;
  final int? currentUserRank;
  final int winProbability;
  final double platformFee;
  final double totalPayable;
  final String? sellerId;
  final String sellerName;
  final double sellerRating;
  final int sellerReviewsCount;
  final int sellerSalesCount;
  final String city;
  final String state;
  final String? serverTimestamp;
  final List<BidHistoryItemModel> recentBids;

  AuctionDetailsModel({
    required this.listingId,
    required this.title,
    required this.productCondition,
    this.primaryImageUrl,
    this.imageUrls = const [],
    required this.startingBid,
    required this.currentHighestBid,
    required this.minNextBid,
    required this.minBidIncrement,
    this.auctionEndTime,
    required this.secondsRemaining,
    required this.timeLeftFormatted,
    required this.totalBids,
    required this.watchingCount,
    this.highestBidderId,
    required this.highestBidderName,
    required this.highestBidderTime,
    required this.status,
    required this.isAuctionEnded,
    required this.isCurrentUserWinning,
    this.currentUserBid,
    this.currentUserRank,
    required this.winProbability,
    required this.platformFee,
    required this.totalPayable,
    this.sellerId,
    required this.sellerName,
    required this.sellerRating,
    required this.sellerReviewsCount,
    required this.sellerSalesCount,
    required this.city,
    required this.state,
    this.serverTimestamp,
    this.recentBids = const [],
  });

  factory AuctionDetailsModel.fromJson(Map<String, dynamic> json) {
    return AuctionDetailsModel(
      listingId: json['listingId'] ?? '',
      title: json['title'] ?? '',
      productCondition: json['productCondition'] ?? '',
      primaryImageUrl: json['primaryImageUrl'],
      imageUrls: (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      startingBid: (json['startingBid'] as num?)?.toDouble() ?? 0.0,
      currentHighestBid: (json['currentHighestBid'] as num?)?.toDouble() ?? 0.0,
      minNextBid: (json['minNextBid'] as num?)?.toDouble() ?? 0.0,
      minBidIncrement: (json['minBidIncrement'] as num?)?.toDouble() ?? 0.0,
      auctionEndTime: json['auctionEndTime'],
      secondsRemaining: json['secondsRemaining'] ?? 0,
      timeLeftFormatted: json['timeLeftFormatted'] ?? '--:--',
      totalBids: json['totalBids'] ?? 0,
      watchingCount: json['watchingCount'] ?? 0,
      highestBidderId: json['highestBidderId'],
      highestBidderName: json['highestBidderName'] ?? '',
      highestBidderTime: json['highestBidderTime'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      isAuctionEnded: json['isAuctionEnded'] ?? false,
      isCurrentUserWinning: json['isCurrentUserWinning'] ?? false,
      currentUserBid: (json['currentUserBid'] as num?)?.toDouble(),
      currentUserRank: json['currentUserRank'],
      winProbability: json['winProbability'] ?? 0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      totalPayable: (json['totalPayable'] as num?)?.toDouble() ?? 0.0,
      sellerId: json['sellerId'],
      sellerName: json['sellerName'] ?? '',
      sellerRating: (json['sellerRating'] as num?)?.toDouble() ?? 0.0,
      sellerReviewsCount: json['sellerReviewsCount'] ?? 0,
      sellerSalesCount: json['sellerSalesCount'] ?? 0,
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      serverTimestamp: json['serverTimestamp'],
      recentBids: (json['recentBids'] as List?)
              ?.map((e) => BidHistoryItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BidHistoryItemModel {
  final String id;
  final String bidderId;
  final String bidderName;
  final String bidderInitials;
  final double amount;
  final String relativeTime;
  final bool isHighest;
  final bool isCurrentUser;

  BidHistoryItemModel({
    required this.id,
    required this.bidderId,
    required this.bidderName,
    required this.bidderInitials,
    required this.amount,
    required this.relativeTime,
    required this.isHighest,
    required this.isCurrentUser,
  });

  factory BidHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return BidHistoryItemModel(
      id: json['id'] ?? '',
      bidderId: json['bidderId'] ?? '',
      bidderName: json['bidderName'] ?? 'Bidder',
      bidderInitials: json['bidderInitials'] ?? 'B',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      relativeTime: json['relativeTime'] ?? 'Just now',
      isHighest: json['isHighest'] ?? json['highest'] ?? false,
      isCurrentUser: json['isCurrentUser'] ?? json['currentUser'] ?? false,
    );
  }
}

class AuctionLiveStatusModel {
  final String listingId;
  final double currentHighestBid;
  final double minNextBid;
  final int totalBids;
  final int watchingCount;
  final int secondsRemaining;
  final String timeLeftFormatted;
  final String status;
  final bool isAuctionEnded;
  final bool isCurrentUserWinning;
  final bool isCurrentUserOutbid;
  final double? currentUserBid;
  final int? currentUserRank;
  final double? behindByAmount;
  final String? highestBidderId;
  final String highestBidderName;
  final String? serverTimestamp;
  final List<BidHistoryItemModel> liveBidFeed;

  AuctionLiveStatusModel({
    required this.listingId,
    required this.currentHighestBid,
    required this.minNextBid,
    required this.totalBids,
    required this.watchingCount,
    required this.secondsRemaining,
    required this.timeLeftFormatted,
    required this.status,
    required this.isAuctionEnded,
    required this.isCurrentUserWinning,
    required this.isCurrentUserOutbid,
    this.currentUserBid,
    this.currentUserRank,
    this.behindByAmount,
    this.highestBidderId,
    required this.highestBidderName,
    this.serverTimestamp,
    this.liveBidFeed = const [],
  });

  factory AuctionLiveStatusModel.fromJson(Map<String, dynamic> json) {
    return AuctionLiveStatusModel(
      listingId: json['listingId'] ?? '',
      currentHighestBid: (json['currentHighestBid'] as num?)?.toDouble() ?? 0.0,
      minNextBid: (json['minNextBid'] as num?)?.toDouble() ?? 0.0,
      totalBids: json['totalBids'] ?? 0,
      watchingCount: json['watchingCount'] ?? 0,
      secondsRemaining: json['secondsRemaining'] ?? 0,
      timeLeftFormatted: json['timeLeftFormatted'] ?? '--:--',
      status: json['status'] ?? 'ACTIVE',
      isAuctionEnded: json['isAuctionEnded'] ?? false,
      isCurrentUserWinning: json['isCurrentUserWinning'] ?? false,
      isCurrentUserOutbid: json['isCurrentUserOutbid'] ?? false,
      currentUserBid: (json['currentUserBid'] as num?)?.toDouble(),
      currentUserRank: json['currentUserRank'],
      behindByAmount: (json['behindByAmount'] as num?)?.toDouble(),
      highestBidderId: json['highestBidderId'],
      highestBidderName: json['highestBidderName'] ?? '',
      serverTimestamp: json['serverTimestamp'],
      liveBidFeed: (json['liveBidFeed'] as List?)
              ?.map((e) => BidHistoryItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WalletModel {
  final String id;
  final double balance;
  final double reservedBalance;
  final double availableBalance;

  WalletModel({
    required this.id,
    required this.balance,
    required this.reservedBalance,
    required this.availableBalance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      reservedBalance: (json['reservedBalance'] as num?)?.toDouble() ?? 0.0,
      availableBalance: (json['availableBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DeliveryAddressModel {
  final String id;
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String pincode;
  final bool isDefault;

  DeliveryAddressModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.pincode,
    required this.isDefault,
  });

  factory DeliveryAddressModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      addressLine: json['addressLine'] ?? '',
      city: json['city'] ?? '',
      pincode: json['pincode'] ?? '',
      isDefault: json['isDefault'] ?? json['default'] ?? false,
    );
  }

  String get formattedAddress => '$addressLine, $city - $pincode';
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String listingId;
  final String productTitle;
  final String productCondition;
  final String? primaryImageUrl;
  final double wonAmount;
  final double platformFee;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String courierPartner;
  final String? trackingNumber;
  final String? estimatedDeliveryDate;
  final String? deliveredAt;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final double sellerRating;
  final int sellerSalesCount;
  final String deliveryAddressFullName;
  final String deliveryAddressPhone;
  final String deliveryAddressLine;
  final String deliveryAddressCity;
  final String deliveryAddressPincode;
  final List<OrderTrackingEventModel> trackingTimeline;
  final bool isReviewed;

  final String orderSource;
  final String deliveryType;
  final String? meetupLocation;
  final String? meetupTime;
  final String? meetupOtp;
  final bool meetupOtpVerified;
  final bool isMeetupConfirmed;
  final bool isSeller;
  final bool isBuyer;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.listingId,
    required this.productTitle,
    required this.productCondition,
    this.primaryImageUrl,
    required this.wonAmount,
    required this.platformFee,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.courierPartner,
    this.trackingNumber,
    this.estimatedDeliveryDate,
    this.deliveredAt,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.sellerRating,
    required this.sellerSalesCount,
    required this.deliveryAddressFullName,
    required this.deliveryAddressPhone,
    required this.deliveryAddressLine,
    required this.deliveryAddressCity,
    required this.deliveryAddressPincode,
    this.trackingTimeline = const [],
    this.isReviewed = false,
    this.orderSource = 'AUCTION',
    this.deliveryType = 'COURIER',
    this.meetupLocation,
    this.meetupTime,
    this.meetupOtp,
    this.meetupOtpVerified = false,
    this.isMeetupConfirmed = false,
    this.isSeller = false,
    this.isBuyer = false,
  });

  bool get isMeetup => deliveryType == 'IN_PERSON_MEETUP';
  bool get isMeetupDelivery => isMeetup;
  bool get isDirectSale => orderSource == 'DIRECT_SALE';

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      listingId: json['listingId'] ?? '',
      productTitle: json['productTitle'] ?? '',
      productCondition: json['productCondition'] ?? 'LIKE_NEW',
      primaryImageUrl: json['primaryImageUrl'],
      wonAmount: (json['wonAmount'] is num)
          ? (json['wonAmount'] as num).toDouble()
          : (json['totalAmount'] is num ? (json['totalAmount'] as num).toDouble() : 0.0),
      platformFee: (json['platformFee'] is num) ? (json['platformFee'] as num).toDouble() : 0.0,
      totalAmount: (json['totalAmount'] is num) ? (json['totalAmount'] as num).toDouble() : 0.0,
      status: json['status'] ?? 'ORDER_CONFIRMED',
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      courierPartner: json['courierPartner'] ?? '',
      trackingNumber: json['trackingNumber'],
      estimatedDeliveryDate: json['estimatedDeliveryDate'],
      deliveredAt: json['deliveredAt'],
      buyerId: json['buyerId'] ?? '',
      buyerName: json['buyerName'] ?? '',
      sellerId: json['sellerId'] ?? '',
      sellerName: json['sellerName'] ?? '',
      sellerRating: (json['sellerRating'] is num) ? (json['sellerRating'] as num).toDouble() : 0.0,
      sellerSalesCount: json['sellerSalesCount'] ?? 0,
      deliveryAddressFullName: json['deliveryAddressFullName'] ?? '',
      deliveryAddressPhone: json['deliveryAddressPhone'] ?? '',
      deliveryAddressLine: json['deliveryAddressLine'] ?? '',
      deliveryAddressCity: json['deliveryAddressCity'] ?? '',
      deliveryAddressPincode: json['deliveryAddressPincode'] ?? '',
      trackingTimeline: (json['trackingTimeline'] as List?)
              ?.map((e) => OrderTrackingEventModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isReviewed: json['isReviewed'] ?? false,
      orderSource: json['orderSource'] ?? 'AUCTION',
      deliveryType: json['deliveryType'] ?? 'COURIER',
      meetupLocation: json['meetupLocation'],
      meetupTime: json['meetupTime'],
      meetupOtp: json['meetupOtp'],
      meetupOtpVerified: json['meetupOtpVerified'] ?? false,
      isMeetupConfirmed: json['isMeetupConfirmed'] == true || json['meetupConfirmed'] == true,
      isSeller: json['isSeller'] ?? json['seller'] ?? false,
      isBuyer: json['isBuyer'] ?? json['buyer'] ?? false,
    );
  }
}

class OrderTrackingEventModel {
  final String id;
  final String status;
  final String title;
  final String? description;
  final String? eventTime;
  final String formattedTime;
  final bool isCompleted;

  OrderTrackingEventModel({
    required this.id,
    required this.status,
    required this.title,
    this.description,
    this.eventTime,
    required this.formattedTime,
    required this.isCompleted,
  });

  factory OrderTrackingEventModel.fromJson(Map<String, dynamic> json) {
    return OrderTrackingEventModel(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      eventTime: json['eventTime'],
      formattedTime: json['formattedTime'] ?? '',
      isCompleted: json['isCompleted'] ?? true,
    );
  }
}

class AuctionEventModel {
  final String eventType;
  final String listingId;
  final double highestBid;
  final String? highestBidderId;
  final String highestBidderDisplayName;
  final int totalBids;
  final double minimumNextBid;
  final double bidIncrement;
  final String? auctionEndTime;
  final int secondsRemaining;
  final String auctionStatus;
  final String serverTimestamp;
  final List<BidHistoryItemModel> recentBids;
  final int? watchingCount;

  AuctionEventModel({
    required this.eventType,
    required this.listingId,
    required this.highestBid,
    this.highestBidderId,
    required this.highestBidderDisplayName,
    required this.totalBids,
    required this.minimumNextBid,
    required this.bidIncrement,
    this.auctionEndTime,
    required this.secondsRemaining,
    required this.auctionStatus,
    required this.serverTimestamp,
    this.recentBids = const [],
    this.watchingCount,
  });

  factory AuctionEventModel.fromJson(Map<String, dynamic> json) {
    return AuctionEventModel(
      eventType: json['eventType'] ?? 'BID_PLACED',
      listingId: json['listingId'] ?? '',
      highestBid: (json['highestBid'] as num?)?.toDouble() ?? 0.0,
      highestBidderId: json['highestBidderId'],
      highestBidderDisplayName: json['highestBidderDisplayName'] ?? '',
      totalBids: json['totalBids'] ?? 0,
      minimumNextBid: (json['minimumNextBid'] as num?)?.toDouble() ?? 0.0,
      bidIncrement: (json['bidIncrement'] as num?)?.toDouble() ?? 0.0,
      auctionEndTime: json['auctionEndTime'],
      secondsRemaining: json['secondsRemaining'] ?? 0,
      auctionStatus: json['auctionStatus'] ?? 'ACTIVE',
      serverTimestamp: json['serverTimestamp'] ?? '',
      recentBids: (json['recentBids'] as List?)
              ?.map((e) => BidHistoryItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      watchingCount: json['watchingCount'],
    );
  }
}

class AuctionWinnerModel {
  final String? orderId;
  final String listingId;
  final String listingTitle;
  final String? listingImageUrl;
  final String? winnerId;
  final String winnerName;
  final String winnerLocality;
  final double winningAmount;
  final bool paymentSecuredInEscrow;
  final String orderStatus;

  AuctionWinnerModel({
    this.orderId,
    required this.listingId,
    required this.listingTitle,
    this.listingImageUrl,
    this.winnerId,
    required this.winnerName,
    required this.winnerLocality,
    required this.winningAmount,
    this.paymentSecuredInEscrow = true,
    required this.orderStatus,
  });

  factory AuctionWinnerModel.fromJson(Map<String, dynamic> json) {
    return AuctionWinnerModel(
      orderId: json['orderId']?.toString(),
      listingId: json['listingId']?.toString() ?? '',
      listingTitle: json['listingTitle']?.toString() ?? '',
      listingImageUrl: json['listingImageUrl']?.toString(),
      winnerId: json['winnerId']?.toString(),
      winnerName: json['winnerName']?.toString() ?? 'Winner',
      winnerLocality: json['winnerLocality']?.toString() ?? 'Verified Buyer',
      winningAmount: (json['winningAmount'] as num?)?.toDouble() ?? 0.0,
      paymentSecuredInEscrow: json['paymentSecuredInEscrow'] ?? true,
      orderStatus: json['orderStatus']?.toString() ?? 'AUCTION_WON',
    );
  }
}
