import 'package:flutter_test/flutter_test.dart';
import 'package:bidly_app/features/chat/models/offer_model.dart';
import 'package:bidly_app/features/chat/models/chat_message_model.dart';
import 'package:bidly_app/features/chat/models/chat_event_model.dart';

void main() {
  group('Offer & Chat Model Real-Time Tests', () {
    test('OfferModel correctly parses pending and countered offers from backend', () {
      final json = {
        'id': 'offer-1',
        'listingId': 'listing-1',
        'listingTitle': 'Sony WH-1000XM4',
        'listingPrice': 18000.0,
        'listingImageUrl': 'https://example.com/img.jpg',
        'buyerId': 'buyer-1',
        'buyerName': 'Rahul V',
        'sellerId': 'seller-1',
        'sellerName': 'Priya S',
        'amount': 15000.0,
        'counterAmount': 16500.0,
        'status': 'COUNTERED',
        'message': 'Can you do 16.5k?',
        'createdAt': '2026-08-31T10:00:00Z',
        'expiresAt': '2026-09-03T10:00:00Z',
        'isBuyer': true,
        'isSeller': false,
      };

      final offer = OfferModel.fromJson(json);

      expect(offer.id, 'offer-1');
      expect(offer.amount, 15000.0);
      expect(offer.counterAmount, 16500.0);
      expect(offer.status, 'COUNTERED');
      expect(offer.isCountered, true);
      expect(offer.isBuyer, true);
      expect(offer.isSeller, false);
      expect(offer.currentEffectiveAmount, 16500.0);
    });

    test('ChatMessageModel correctly parses offer and counter messages', () {
      final json = {
        'id': 'msg-1',
        'roomId': 'room-1',
        'senderId': 'buyer-1',
        'senderName': 'Rahul V',
        'clientMessageId': 'client-uuid-1',
        'content': 'Submitted an offer of ₹15000',
        'type': 'OFFER',
        'offerAmount': 15000.0,
        'status': 'SENT',
        'createdAt': '2026-08-31T10:00:00Z',
      };

      final msg = ChatMessageModel.fromJson(json, currentUserId: 'buyer-1');

      expect(msg.id, 'msg-1');
      expect(msg.isMine, true);
      expect(msg.type, 'OFFER');
      expect(msg.offerAmount, 15000.0);
      expect(msg.isOffer, true);
    });

    test('ChatEventModel handles OFFER_UPDATED and NEW_MESSAGE real-time STOMP frames', () {
      final offerUpdatedJson = {
        'eventType': 'OFFER_UPDATED',
        'roomId': 'room-1',
        'offerId': 'offer-1',
        'offerStatus': 'COUNTERED',
        'offerAmount': 15000.0,
        'counterAmount': 16500.0,
      };

      final offerEvent = ChatEventModel.fromJson(offerUpdatedJson);
      expect(offerEvent.eventType, 'OFFER_UPDATED');
      expect(offerEvent.offerStatus, 'COUNTERED');
      expect(offerEvent.counterAmount, 16500.0);

      final msgJson = {
        'eventType': 'NEW_MESSAGE',
        'roomId': 'room-1',
        'message': {
          'id': 'msg-2',
          'roomId': 'room-1',
          'senderId': 'seller-1',
          'senderName': 'Priya S',
          'content': 'Counter offer of ₹16500',
          'type': 'OFFER_COUNTERED',
          'offerAmount': 16500.0,
          'status': 'SENT',
          'createdAt': '2026-08-31T10:05:00Z',
        }
      };

      final msgEvent = ChatEventModel.fromJson(msgJson, currentUserId: 'buyer-1');
      expect(msgEvent.eventType, 'NEW_MESSAGE');
      expect(msgEvent.message, isNotNull);
      expect(msgEvent.message!.isMine, false);
      expect(msgEvent.message!.offerAmount, 16500.0);
      expect(msgEvent.message!.type, 'OFFER_COUNTERED');
    });
  });
}
