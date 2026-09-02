import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class NotificationItemModel {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final bool isUnread;
  final String type; // NEW_OFFER, OFFER_ACCEPTED, OFFER_REJECTED, MEETUP_SCHEDULED, OTP_READY, OTP_VERIFIED, TRANSACTION_COMPLETED, ITEM_SOLD
  final String? actionLabel;
  final String? targetRoute;
  final String? targetId;
  final String? listingId;
  final String? offerId;
  final String? orderId;
  final Map<String, dynamic>? metadata;

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
    this.listingId,
    this.offerId,
    this.orderId,
    this.metadata,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? meta;
    if (json['metadata'] != null) {
      if (json['metadata'] is Map) {
        meta = Map<String, dynamic>.from(json['metadata'] as Map);
      } else if (json['metadata'] is String) {
        try {
          meta = jsonDecode(json['metadata'] as String) as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    return NotificationItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      timeAgo: json['timeAgo']?.toString() ?? 'Just now',
      isUnread: json['isRead'] == false || json['unread'] == true,
      type: json['type']?.toString() ?? 'SYSTEM',
      actionLabel: json['actionLabel']?.toString(),
      targetRoute: json['targetRoute']?.toString(),
      targetId: json['targetId']?.toString(),
      listingId: json['listingId']?.toString(),
      offerId: json['offerId']?.toString(),
      orderId: json['orderId']?.toString(),
      metadata: meta,
    );
  }

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
    String? listingId,
    String? offerId,
    String? orderId,
    Map<String, dynamic>? metadata,
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
      listingId: listingId ?? this.listingId,
      offerId: offerId ?? this.offerId,
      orderId: orderId ?? this.orderId,
      metadata: metadata ?? this.metadata,
    );
  }
}

class NotificationsState {
  final List<NotificationItemModel> notifications;
  final bool isLoading;
  final int unreadCount;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<NotificationItemModel>? notifications,
    bool? isLoading,
    int? unreadCount,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final ApiClient _apiClient;

  NotificationsNotifier(this._apiClient) : super(const NotificationsState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _apiClient.get('/notifications');
      if (res.data != null && res.data['success'] == true && res.data['data'] != null) {
        final list = (res.data['data'] as List)
            .map((item) => NotificationItemModel.fromJson(item as Map<String, dynamic>))
            .toList();

        final unread = list.where((n) => n.isUnread).length;
        state = state.copyWith(
          notifications: list,
          unreadCount: unread,
          isLoading: false,
        );
        return;
      }
    } catch (_) {}

    state = state.copyWith(isLoading: false);
  }

  void addRealtimeNotification(NotificationItemModel item) {
    final updated = [item, ...state.notifications.where((n) => n.id != item.id)];
    final unread = updated.where((n) => n.isUnread).length;
    state = state.copyWith(notifications: updated, unreadCount: unread);
  }

  Future<void> markAllAsRead() async {
    final updated = state.notifications.map((n) => n.copyWith(isUnread: false)).toList();
    state = state.copyWith(notifications: updated, unreadCount: 0);
    try {
      await _apiClient.post('/notifications/read-all');
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    final updated = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isUnread: false);
      }
      return n;
    }).toList();
    final unread = updated.where((n) => n.isUnread).length;
    state = state.copyWith(notifications: updated, unreadCount: unread);
    try {
      await _apiClient.post('/notifications/$id/read');
    } catch (_) {}
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsNotifier(apiClient);
});
