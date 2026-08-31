import 'package:flutter_test/flutter_test.dart';
import 'package:bidly_app/features/auction/models/auction_model.dart';

void main() {
  group('Auction Model & Status Tests', () {
    test('AuctionDetailsModel correctly parses real API data without fake defaults', () {
      final json = {
        'listingId': 'listing-123',
        'title': 'iPhone 13 Pro 256GB',
        'productCondition': 'LIKE_NEW',
        'startingBid': 40000.0,
        'currentHighestBid': 42500.0,
        'minNextBid': 43000.0,
        'minBidIncrement': 500.0,
        'auctionEndTime': '2026-08-31T20:00:00Z',
        'secondsRemaining': 3600,
        'timeLeftFormatted': '01:00:00',
        'totalBids': 5,
        'watchingCount': 14,
        'highestBidderId': 'user-1',
        'highestBidderName': 'Rahul V',
        'highestBidderTime': '2 min ago',
        'status': 'ACTIVE',
        'isAuctionEnded': false,
        'isCurrentUserWinning': true,
        'currentUserBid': 42500.0,
        'currentUserRank': 1,
        'winProbability': 85,
        'platformFee': 860.0,
        'totalPayable': 43860.0,
        'sellerId': 'seller-1',
        'sellerName': 'Tech Hub',
        'sellerRating': 4.8,
        'sellerReviewsCount': 0,
        'sellerSalesCount': 12,
        'city': 'Chennai',
        'state': 'Tamil Nadu',
        'serverTimestamp': '2026-08-31T19:00:00Z',
        'recentBids': [
          {
            'id': 'bid-1',
            'bidderId': 'user-1',
            'bidderName': 'Rahul V',
            'bidderInitials': 'RV',
            'amount': 42500.0,
            'createdAt': '2026-08-31T18:58:00Z',
            'timeAgo': '2 min ago',
            'isHighest': true,
            'isUser': true,
          }
        ]
      };

      final details = AuctionDetailsModel.fromJson(json);

      expect(details.listingId, 'listing-123');
      expect(details.currentHighestBid, 42500.0);
      expect(details.totalBids, 5);
      expect(details.watchingCount, 14);
      expect(details.isCurrentUserWinning, true);
      expect(details.sellerRating, 4.8);
      expect(details.sellerSalesCount, 12);
      expect(details.recentBids.length, 1);
      expect(details.recentBids.first.bidderName, 'Rahul V');
    });

    test('AuctionLiveStatusModel correctly parses live status payload', () {
      final json = {
        'listingId': 'listing-123',
        'currentHighestBid': 45000.0,
        'minNextBid': 45500.0,
        'totalBids': 6,
        'watchingCount': 18,
        'secondsRemaining': 1800,
        'timeLeftFormatted': '30:00',
        'status': 'ACTIVE',
        'isAuctionEnded': false,
        'isCurrentUserWinning': false,
        'isCurrentUserOutbid': true,
        'currentUserBid': 42500.0,
        'currentUserRank': 2,
        'behindByAmount': 2500.0,
        'highestBidderId': 'user-2',
        'highestBidderName': 'Priya S',
        'serverTimestamp': '2026-08-31T19:30:00Z',
        'liveBidFeed': []
      };

      final live = AuctionLiveStatusModel.fromJson(json);

      expect(live.currentHighestBid, 45000.0);
      expect(live.minNextBid, 45500.0);
      expect(live.isCurrentUserOutbid, true);
      expect(live.behindByAmount, 2500.0);
      expect(live.highestBidderName, 'Priya S');
    });

    test('AuctionEventModel correctly handles BID_WITHDRAWN event', () {
      final json = {
        'eventType': 'BID_WITHDRAWN',
        'listingId': 'listing-123',
        'highestBid': 42500.0,
        'highestBidderId': 'user-1',
        'highestBidderDisplayName': 'Rahul V',
        'totalBids': 5,
        'minimumNextBid': 43000.0,
        'bidIncrement': 500.0,
        'auctionEndTime': '2026-08-31T20:00:00Z',
        'secondsRemaining': 3600,
        'auctionStatus': 'ACTIVE',
        'serverTimestamp': '2026-08-31T19:00:00Z',
        'recentBids': []
      };

      final event = AuctionEventModel.fromJson(json);

      expect(event.eventType, 'BID_WITHDRAWN');
      expect(event.highestBid, 42500.0);
      expect(event.highestBidderDisplayName, 'Rahul V');
      expect(event.totalBids, 5);
    });
  });
}
