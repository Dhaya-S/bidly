import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bidly_app/features/profile/providers/notifications_provider.dart';
import 'package:bidly_app/core/api/api_client.dart';

class MockApiClient extends ApiClient {
  MockApiClient() : super(const FlutterSecureStorage());
}

void main() {
  group('Notifications Isolation and Role Routing Tests', () {
    test('NotificationItemModel correctly parses userId and attributes', () {
      final json = {
        'id': 'notif-101',
        'userId': 'user-buyer-1',
        'title': 'Counter Offer Received',
        'body': 'Seller countered at ₹4,500',
        'type': 'OFFER_COUNTERED',
        'actionLabel': 'View Counter Offer',
        'listingId': 'list-99',
        'metadata': {'buyerId': 'user-buyer-1', 'sellerId': 'user-seller-2'},
      };

      final model = NotificationItemModel.fromJson(json);
      expect(model.id, 'notif-101');
      expect(model.userId, 'user-buyer-1');
      expect(model.type, 'OFFER_COUNTERED');
      expect(model.actionLabel, 'View Counter Offer');
      expect(model.metadata?['buyerId'], 'user-buyer-1');
    });

    test('NotificationsNotifier drops incoming notification if userId does not match current user', () {
      final notifier = NotificationsNotifier(MockApiClient(), 'user-buyer-1');

      final notifForBuyer = NotificationItemModel(
        id: 'n-1',
        userId: 'user-buyer-1',
        title: 'For Buyer',
        body: 'Your offer was countered',
        timeAgo: 'Just now',
        type: 'OFFER_COUNTERED',
      );

      final notifForSeller = NotificationItemModel(
        id: 'n-2',
        userId: 'user-seller-2',
        title: 'For Seller',
        body: 'New offer received',
        timeAgo: 'Just now',
        type: 'NEW_OFFER',
      );

      // Add valid notification for current user
      notifier.addRealtimeNotification(notifForBuyer);
      expect(notifier.state.notifications.length, 1);
      expect(notifier.state.notifications.first.id, 'n-1');

      // Add notification for another user - must be dropped
      notifier.addRealtimeNotification(notifForSeller);
      expect(notifier.state.notifications.length, 1);
      expect(notifier.state.notifications.first.id, 'n-1');
    });

    test('NotificationsNotifier drops all incoming notifications when user is logged out (userId is null)', () {
      final notifier = NotificationsNotifier(MockApiClient(), null);

      final notif = NotificationItemModel(
        id: 'n-1',
        userId: 'user-buyer-1',
        title: 'For Buyer',
        body: 'Any notification',
        timeAgo: 'Just now',
        type: 'OFFER_ACCEPTED',
      );

      notifier.addRealtimeNotification(notif);
      expect(notifier.state.notifications.isEmpty, true);
      expect(notifier.state.unreadCount, 0);
    });

    test('NotificationsNotifier isolates state across user switch', () {
      // User 1 logs in
      final notifierUser1 = NotificationsNotifier(MockApiClient(), 'user-1');
      notifierUser1.addRealtimeNotification(const NotificationItemModel(
        id: 'n-user1',
        userId: 'user-1',
        title: 'User 1 message',
        body: 'Offer update',
        timeAgo: 'Just now',
        type: 'OFFER_ACCEPTED',
      ));
      expect(notifierUser1.state.notifications.length, 1);

      // User 2 logs in
      final notifierUser2 = NotificationsNotifier(MockApiClient(), 'user-2');
      expect(notifierUser2.state.notifications.isEmpty, true);

      // Add notification for User 2
      notifierUser2.addRealtimeNotification(const NotificationItemModel(
        id: 'n-user2',
        userId: 'user-2',
        title: 'User 2 message',
        body: 'Sale completed',
        timeAgo: 'Just now',
        type: 'TRANSACTION_COMPLETED',
      ));
      expect(notifierUser2.state.notifications.length, 1);
      expect(notifierUser2.state.notifications.first.id, 'n-user2');
    });
  });
}
