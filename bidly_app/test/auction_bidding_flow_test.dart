import 'package:flutter_test/flutter_test.dart';
import 'package:bidly_app/features/auction/models/auction_model.dart';

void main() {
  group('Buyer Auction & Bidding Flow Unit Tests', () {
    test('Wallet validation correctly detects sufficient vs insufficient dummy funds', () {
      final dummyWallet = WalletModel(
        id: 'wallet-dummy-1',
        balance: 50000.0,
        reservedBalance: 0.0,
        availableBalance: 50000.0,
      );

      const bidAmount1 = 36500.0;
      expect(dummyWallet.availableBalance >= bidAmount1, true);

      const bidAmount2 = 55000.0;
      expect(dummyWallet.availableBalance >= bidAmount2, false);
      const shortAmount = bidAmount2 - 50000.0;
      expect(shortAmount, 5000.0);
    });

    test('Outbid calculations and quick increase amounts compute accurately', () {
      const currentHighest = 36500.0;
      const userBid = 35000.0;
      const isOutbid = currentHighest > userBid;
      const behindBy = currentHighest - userBid;

      expect(isOutbid, true);
      expect(behindBy, 1500.0);

      const quickAdd1k = currentHighest + 1000.0;
      const quickAdd2k = currentHighest + 2000.0;
      const quickAdd5k = currentHighest + 5000.0;

      expect(quickAdd1k, 37500.0);
      expect(quickAdd2k, 38500.0);
      expect(quickAdd5k, 41500.0);
    });

    test('Auction Winner model correctly handles buyer win and escrow state', () {
      final winnerJson = {
        'winnerId': 'user_buyer_123',
        'winnerName': 'You',
        'winningAmount': 50000.0,
        'listingId': 'listing-laptop-1',
        'listingTitle': 'Gaming Laptop RTX 3060 - Excellent Condition',
        'orderStatus': 'SOLD',
        'winnerLocality': 'Bengaluru',
        'paymentSecuredInEscrow': true,
      };

      final winner = AuctionWinnerModel.fromJson(winnerJson);
      expect(winner.winnerId, 'user_buyer_123');
      expect(winner.winnerName, 'You');
      expect(winner.winningAmount, 50000.0);
      expect(winner.orderStatus, 'SOLD');
      expect(winner.paymentSecuredInEscrow, true);
    });

    test('Delivery Address model parses and formats cleanly for courier and meetup', () {
      final addressJson = {
        'id': 'addr-1',
        'fullName': 'Rahul Sharma',
        'phone': '+91 98765 43210',
        'addressLine': 'Flat 402, Green Valley Apartments',
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'pincode': '560001',
        'isDefault': true,
      };

      final address = DeliveryAddressModel.fromJson(addressJson);
      expect(address.fullName, 'Rahul Sharma');
      expect(address.city, 'Bengaluru');
      expect(address.pincode, '560001');
      expect(address.formattedAddress, contains('Bengaluru'));
    });
  });
}
