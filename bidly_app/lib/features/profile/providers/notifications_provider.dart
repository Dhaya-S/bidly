import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationItemModel {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final bool isUnread;
  final String type; // OFFER, BID, SHIPPED, MEETUP, DELIVERED
  final String? actionLabel;
  final String? targetRoute;
  final String? targetId;

  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.isUnread = true,
    required this.type,
    this.actionLabel,
    this.targetRoute,
    this.targetId,
  });

  NotificationItemModel copyWith({
    String? id,
    String? title,
    String? body,
    String? timeAgo,
    bool? isUnread,
    String? type,
    String? actionLabel,
    String? targetRoute,
    String? targetId,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timeAgo: timeAgo ?? this.timeAgo,
      isUnread: isUnread ?? this.isUnread,
      type: type ?? this.type,
      actionLabel: actionLabel ?? this.actionLabel,
      targetRoute: targetRoute ?? this.targetRoute,
      targetId: targetId ?? this.targetId,
    );
  }
}

class NotificationsState {
  final List<NotificationItemModel> notifications;
  final bool isLoading;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => n.isUnread).length;

  NotificationsState copyWith({
    List<NotificationItemModel>? notifications,
    bool? isLoading,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier()
      : super(NotificationsState(notifications: _defaultNotifications()));

  static List<NotificationItemModel> _defaultNotifications() {
    return [
      const NotificationItemModel(
        id: 'notif-1',
        title: 'New Offer Received',
        body: 'Priya Menon made an offer on Samsung Galaxy S23 Ultra',
        timeAgo: '2m ago',
        isUnread: true,
        type: 'OFFER',
        actionLabel: 'View Offer',
      ),
      const NotificationItemModel(
        id: 'notif-2',
        title: 'New Bid on MacBook Air M2',
        body: 'Kiran T. placed a bid of ₹75,000',
        timeAgo: '18m ago',
        isUnread: true,
        type: 'BID',
        actionLabel: 'View Offer',
      ),
      const NotificationItemModel(
        id: 'notif-3',
        title: 'Your auction item has shipped',
        body: 'iPhone 13 Pro is on its way · Tap to track',
        timeAgo: '3h ago',
        isUnread: true,
        type: 'SHIPPED',
      ),
      const NotificationItemModel(
        id: 'notif-4',
        title: 'Meeting completed?',
        body: 'Your meetup for MacBook Air M2 was scheduled for 3:00 PM',
        timeAgo: '45m ago',
        isUnread: true,
        type: 'MEETUP',
      ),
      const NotificationItemModel(
        id: 'notif-5',
        title: 'Product delivered',
        body: 'iPhone 13 Pro has been delivered · Confirm receipt',
        timeAgo: '1h ago',
        isUnread: true,
        type: 'DELIVERED',
      ),
    ];
  }

  void markAllAsRead() {
    final updated = state.notifications.map((n) => n.copyWith(isUnread: false)).toList();
    state = state.copyWith(notifications: updated);
  }

  void markAsRead(String id) {
    final updated = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isUnread: false);
      }
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});
