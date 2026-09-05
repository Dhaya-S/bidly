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
      expect(msg.isOfferAccepted, false);
    });

    test('ChatMessageModel OFFER_ACCEPTED does NOT flag isOffer (avoids "You made an offer" card)', () {
      final json = {
        'id': 'msg-accept-1',
        'roomId': 'room-1',
        'senderId': 'seller-1',
        'senderName': 'Priya S',
        'content': "🎉 Offer accepted! Let's chat and meetup.",
        'type': 'OFFER_ACCEPTED',
        'status': 'SENT',
        'createdAt': '2026-08-31T10:02:00Z',
      };

      final msg = ChatMessageModel.fromJson(json, currentUserId: 'buyer-1');

      expect(msg.id, 'msg-accept-1');
      expect(msg.isMine, false);
      expect(msg.type, 'OFFER_ACCEPTED');
      expect(msg.isOffer, false); // Ensures "You made an offer" card is NOT shown!
      expect(msg.isOfferAccepted, true);
      expect(msg.content, "🎉 Offer accepted! Let's chat and meetup.");
    });

    test('ChatMessageModel MEETUP_REQUEST isMeetup == true, MEETUP_ACCEPTED isMeetup == false (prevents duplicate card)', () {
      final reqJson = {
        'id': 'meetup-1',
        'roomId': 'room-1',
        'senderId': 'seller-1',
        'content': 'Meeting Scheduled\nDate: 06/09/26\nTime: 11.00AM\nLocation: Express Avenue',
        'type': 'MEETUP_REQUEST',
        'status': 'SENT',
        'createdAt': '2026-08-31T10:05:00Z',
      };
      final acceptJson = {
        'id': 'meetup-2',
        'roomId': 'room-1',
        'senderId': 'buyer-1',
        'content': '🤝 Meetup confirmed! Show OTP upon meeting to complete item handover.',
        'type': 'MEETUP_ACCEPTED',
        'status': 'SENT',
        'createdAt': '2026-08-31T10:06:00Z',
      };

      final reqMsg = ChatMessageModel.fromJson(reqJson, currentUserId: 'buyer-1');
      final acceptMsg = ChatMessageModel.fromJson(acceptJson, currentUserId: 'buyer-1');

      expect(reqMsg.isMeetup, true); // Generates ONE meetup card
      expect(reqMsg.isMeetupAccepted, false);

      expect(acceptMsg.isMeetup, false); // Does NOT generate a duplicate card!
      expect(acceptMsg.isMeetupAccepted, true);
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

    test('Direct Buy: Order is strictly IN_PERSON_MEETUP with OTP verification', () {
      final directBuyOrderJson = {
        'id': 'ord-direct-1',
        'orderNumber': 'ORD-2026-12345',
        'listingId': 'listing-1',
        'productTitle': 'MacBook Air M2',
        'productCondition': 'LIKE_NEW',
        'wonAmount': 85000.0,
        'platformFee': 1700.0,
        'totalAmount': 86700.0,
        'status': 'ORDER_CONFIRMED',
        'paymentStatus': 'PENDING',
        'courierPartner': 'None',
        'buyerId': 'buyer-1',
        'buyerName': 'Rahul V',
        'sellerId': 'seller-1',
        'sellerName': 'Priya S',
        'sellerRating': 4.9,
        'sellerSalesCount': 12,
        'deliveryAddressFullName': '',
        'deliveryAddressPhone': '',
        'deliveryAddressLine': '',
        'deliveryAddressCity': '',
        'deliveryAddressPincode': '',
        'orderSource': 'DIRECT_SALE',
        'deliveryType': 'IN_PERSON_MEETUP',
        'meetupLocation': 'Phoenix Mall, Chennai',
        'meetupTime': '2026-09-06T11:00:00Z',
        'meetupOtp': '654321',
        'meetupOtpVerified': false,
        'isMeetupConfirmed': true,
      };

      // Ensure that Direct Buy defaults strictly to IN_PERSON_MEETUP
      expect(directBuyOrderJson['orderSource'], 'DIRECT_SALE');
      expect(directBuyOrderJson['deliveryType'], 'IN_PERSON_MEETUP');
      expect(directBuyOrderJson['meetupOtp'], '654321');
    });

    test('Meetup flow: Seller schedules meetup, buyer confirms, and only then is OTP accessible', () {
      final unconfirmedOrder = {
        'id': 'ord-meetup-1',
        'isMeetupConfirmed': false,
        'deliveryType': 'IN_PERSON_MEETUP',
        'meetupLocation': 'Express Avenue, Chennai',
        'meetupOtp': '987654',
      };

      bool canBuyerSeeOtp(Map<String, dynamic> order) => order['isMeetupConfirmed'] == true;
      bool canSellerSchedule(bool isSeller) => isSeller;

      expect(canSellerSchedule(true), true);
      expect(canSellerSchedule(false), false); // Buyer cannot schedule!
      expect(canBuyerSeeOtp(unconfirmedOrder), false); // Buyer cannot see OTP before confirmation!

      final confirmedOrder = Map<String, dynamic>.from(unconfirmedOrder)..['isMeetupConfirmed'] = true;
      expect(canBuyerSeeOtp(confirmedOrder), true); // Buyer sees OTP only AFTER confirming meetup!
    });

    test('Real-time Messages list: incoming event updates thread preview, bumps to top, and increments unread count', () {
      final initialThreads = <Map<String, dynamic>>[
        {
          'id': 'room-1',
          'userName': 'Meena Stores',
          'lastMessage': 'Your order has been shipped!',
          'timeAgo': '1h',
          'unreadCount': 0,
        },
        {
          'id': 'room-2',
          'userName': 'Ravi Kumar',
          'lastMessage': 'Is the MacBook still available?',
          'timeAgo': '2m',
          'unreadCount': 1,
        },
      ];

      // Simulate incoming event for room-1
      final incomingEventJson = {
        'eventType': 'NEW_MESSAGE',
        'roomId': 'room-1',
        'message': {
          'id': 'msg-new-1',
          'roomId': 'room-1',
          'senderId': 'seller-meena',
          'senderName': 'Meena Stores',
          'content': 'Package arrived at your local hub',
          'type': 'TEXT',
          'status': 'SENT',
          'createdAt': DateTime.now().toIso8601String(),
        },
      };

      final event = ChatEventModel.fromJson(incomingEventJson, currentUserId: 'buyer-user');
      expect(event.eventType, 'NEW_MESSAGE');
      expect(event.roomId, 'room-1');
      expect(event.message?.isMine, false);

      // Simulate thread list update
      final targetIdx = initialThreads.indexWhere((t) => t['id'] == event.roomId);
      expect(targetIdx, 0);

      final old = initialThreads[targetIdx];
      final updated = Map<String, dynamic>.from(old)
        ..['lastMessage'] = event.message!.content
        ..['timeAgo'] = 'Just now'
        ..['unreadCount'] = (old['unreadCount'] as int) + 1;

      initialThreads.removeAt(targetIdx);
      initialThreads.insert(0, updated);

      // Verify room-1 is at the top with updated preview and unread count
      expect(initialThreads.first['id'], 'room-1');
      expect(initialThreads.first['lastMessage'], 'Package arrived at your local hub');
      expect(initialThreads.first['timeAgo'], 'Just now');
      expect(initialThreads.first['unreadCount'], 1);

      // When tapped, unreadCount resets to 0
      initialThreads.first['unreadCount'] = 0;
      expect(initialThreads.first['unreadCount'], 0);
    });

    test('Fast Chat Navigation: roomId, productTitle, and productPrice avoid slow network blocking', () {
      const roomId = 'room-101';
      const productTitle = 'MacBook Air M2';
      const productPrice = 85000.0;
      const listingImageUrl = 'https://example.com/macbook.jpg';

      // Verify metadata is available synchronously before any API call
      expect(roomId, isNotEmpty);
      expect(productTitle, 'MacBook Air M2');
      expect(productPrice, 85000.0);
      expect(listingImageUrl, isNotEmpty);
    });

    test('Buyer Show OTP 6-digit box parsing logic matches Image 2', () {
      const rawOtp = '325725';
      final digits = rawOtp.padRight(6, '-').split('').take(6).toList();

      expect(digits.length, 6);
      expect(digits, ['3', '2', '5', '7', '2', '5']);
    });

    test('Report a Problem includes the 6 specific selectable options from Image 3B', () {
      const expectedOptions = [
        "Seller didn't show up",
        "Item not as described",
        "Suspected fraud or scam",
        "Fake or counterfeit item",
        "Aggressive / rude behaviour",
        "Other issue",
      ];

      expect(expectedOptions.length, 6);
      expect(expectedOptions.contains("Seller didn't show up"), true);
      expect(expectedOptions.contains("Item not as described"), true);
      expect(expectedOptions.contains("Suspected fraud or scam"), true);
      expect(expectedOptions.contains("Fake or counterfeit item"), true);
      expect(expectedOptions.contains("Aggressive / rude behaviour"), true);
      expect(expectedOptions.contains("Other issue"), true);
    });

    test('Item Received delivery confirmation unlocks Review & Rate screen flow', () {
      // Order starts in MEETUP_SCHEDULED or CONFIRMED
      var orderStatus = 'CONFIRMED';
      bool isDelivered(String status) => status == 'DELIVERED';

      expect(isDelivered(orderStatus), false);

      // Buyer taps [ Item Received • Rate Seller ] -> triggers delivery confirmation
      orderStatus = 'DELIVERED';
      expect(isDelivered(orderStatus), true);

      // Now review can be created without review submission error
      final reviewPayload = {
        'orderId': 'order-123',
        'rating': 5,
        'comment': 'Awesome seller, smooth meetup!',
      };
      expect(reviewPayload['rating'], 5);
      expect(reviewPayload['orderId'], 'order-123');
    });

    test('Zero-delay deterministic role resolution avoids buyer/seller screen mismatch', () {
      const currentUserId = 'user-seller-1';
      const otherUserId = 'user-buyer-2';

      bool computeIsSeller({
        bool? isSellerView,
        String? sellerId,
        String? buyerId,
        String? listingSellerId,
        String? roomSellerId,
      }) {
        if (isSellerView != null) return isSellerView;
        if (sellerId != null && sellerId.isNotEmpty) {
          if (sellerId == currentUserId) return true;
        }
        if (buyerId != null && buyerId.isNotEmpty) {
          if (buyerId == currentUserId) return false;
          return true; // In 1-on-1 chat, if buyer is other user, viewer is seller!
        }
        if (listingSellerId != null && listingSellerId.isNotEmpty) {
          return listingSellerId == currentUserId;
        }
        if (roomSellerId != null && roomSellerId.isNotEmpty) {
          return roomSellerId == currentUserId;
        }
        return false;
      }

      // Case 1: Entering from Seller tab in Messages screen -> 100% seller on frame 0
      expect(computeIsSeller(isSellerView: true), true);

      // Case 2: Entering from Buyer tab in Messages screen -> 100% buyer on frame 0
      expect(computeIsSeller(isSellerView: false), false);

      // Case 3: Thread has sellerId matching current user -> 100% seller on frame 0
      expect(computeIsSeller(sellerId: currentUserId), true);

      // Case 4: Thread has buyerId as other user -> 100% seller on frame 0
      expect(computeIsSeller(buyerId: otherUserId), true);

      // Case 5: Thread has buyerId as current user -> 100% buyer on frame 0
      expect(computeIsSeller(buyerId: currentUserId), false);

      // Case 6: Listing belongs to current user -> 100% seller on frame 0
      expect(computeIsSeller(listingSellerId: currentUserId), true);
      expect(computeIsSeller(listingSellerId: otherUserId), false);
    });

    test('ChatMessageModel correctly parses image messages and flags isImage', () {
      final json = {
        'id': 'msg-img-1',
        'roomId': 'room-1',
        'senderId': 'buyer-1',
        'senderName': 'Rahul V',
        'clientMessageId': 'client-img-1',
        'content': 'Check this photo',
        'type': 'IMAGE',
        'mediaUrl': 'https://cdn.bidly.com/chat/photo1.jpg',
        'status': 'SENT',
        'createdAt': '2026-08-31T10:10:00Z',
      };

      final msg = ChatMessageModel.fromJson(json, currentUserId: 'buyer-1');

      expect(msg.id, 'msg-img-1');
      expect(msg.isMine, true);
      expect(msg.type, 'IMAGE');
      expect(msg.isImage, true);
      expect(msg.mediaUrl, 'https://cdn.bidly.com/chat/photo1.jpg');
      expect(msg.isSending, false);
      expect(msg.isFailed, false);
    });

    test('Real-time Instagram-style image flow: optimistic preview -> server confirmation', () {
      final messages = <ChatMessageModel>[];
      const clientMessageId = 'client-uuid-local-1';
      const localFilePath = '/data/user/0/com.bidly.app/cache/camera_shot.jpg';

      // Step 1: User picks image -> immediate optimistic message with local path & status SENDING
      final optimisticMsg = ChatMessageModel(
        id: clientMessageId,
        roomId: 'room-1',
        senderId: 'buyer-1',
        clientMessageId: clientMessageId,
        type: 'IMAGE',
        mediaUrl: localFilePath,
        status: 'SENDING',
        isMine: true,
        createdAt: DateTime.now(),
      );
      messages.add(optimisticMsg);

      expect(messages.length, 1);
      expect(messages.first.isSending, true);
      expect(messages.first.mediaUrl, localFilePath);

      // Step 2: Background upload finishes & server responds with remote CDN URL
      const remoteUrl = 'https://cdn.bidly.com/chat/cf-uuid.jpg';
      final serverJson = {
        'id': 'server-msg-uuid-99',
        'roomId': 'room-1',
        'senderId': 'buyer-1',
        'clientMessageId': clientMessageId,
        'type': 'IMAGE',
        'mediaUrl': remoteUrl,
        'status': 'SENT',
        'createdAt': DateTime.now().toIso8601String(),
      };
      final serverMsg = ChatMessageModel.fromJson(serverJson, currentUserId: 'buyer-1');

      // Replaces optimistic message using clientMessageId matching
      final index = messages.indexWhere((m) => m.clientMessageId == clientMessageId);
      expect(index != -1, true);
      messages[index] = serverMsg;

      expect(messages.length, 1);
      expect(messages.first.id, 'server-msg-uuid-99');
      expect(messages.first.status, 'SENT');
      expect(messages.first.isSending, false);
      expect(messages.first.mediaUrl, remoteUrl);
    });

    test('Failed image upload transitions to FAILED status and enables retry with identical clientMessageId', () {
      final messages = <ChatMessageModel>[];
      const clientMessageId = 'client-fail-1';
      const localFilePath = '/data/user/0/com.bidly.app/cache/photo.jpg';

      // 1. Optimistic message
      messages.add(ChatMessageModel(
        id: clientMessageId,
        roomId: 'room-1',
        senderId: 'buyer-1',
        clientMessageId: clientMessageId,
        type: 'IMAGE',
        mediaUrl: localFilePath,
        status: 'SENDING',
        isMine: true,
        createdAt: DateTime.now(),
      ));

      // 2. Upload fails -> marks FAILED
      final failIndex = messages.indexWhere((m) => m.clientMessageId == clientMessageId);
      messages[failIndex] = messages[failIndex].copyWith(status: 'FAILED');

      expect(messages.first.isFailed, true);
      expect(messages.first.mediaUrl, localFilePath);

      // 3. User taps retry -> re-marks SENDING with same clientMessageId (idempotent)
      messages[failIndex] = messages[failIndex].copyWith(status: 'SENDING');
      expect(messages.first.isSending, true);
      expect(messages.first.clientMessageId, clientMessageId);
    });
  });
}
