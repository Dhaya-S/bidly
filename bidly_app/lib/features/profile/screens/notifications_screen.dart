import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../providers/notifications_provider.dart';

import '../../chat/widgets/new_offer_bottom_sheet.dart';
import '../../chat/widgets/buyer_show_otp_modal.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _handleNotificationTap(BuildContext context, WidgetRef ref, NotificationItemModel notif) {
    ref.read(notificationsProvider.notifier).markAsRead(notif.id);

    if (notif.type == 'NEW_OFFER' || notif.type == 'OFFER') {
      final listingId = notif.listingId ?? notif.targetId;
      if (listingId != null && listingId.isNotEmpty) {
        final offerAmount = (notif.metadata?['offerAmount'] != null)
            ? (double.tryParse(notif.metadata!['offerAmount'].toString()) ?? 0.0)
            : 0.0;
        final listingPrice = (notif.metadata?['listingPrice'] != null)
            ? (double.tryParse(notif.metadata!['listingPrice'].toString()) ?? 0.0)
            : 0.0;
        final buyerName = notif.metadata?['buyerName']?.toString() ?? 'Buyer';
        final offerId = notif.offerId ?? notif.targetId ?? notif.id;

        NewOfferBottomSheet.show(
          context,
          offerId: offerId,
          listingId: listingId,
          buyerName: buyerName,
          offerAmount: offerAmount,
          productTitle: notif.body,
          listingPrice: listingPrice,
        );
        return;
      }
      context.push(AppRoutes.chatList);
    } else if (notif.type == 'MEETUP_SCHEDULED' || notif.type == 'OTP_READY') {
      final orderId = notif.orderId ?? notif.targetId;
      if (orderId != null && orderId.isNotEmpty) {
        BuyerShowOtpModal.show(context, orderId: orderId);
        return;
      }
      context.push(AppRoutes.orders);
    } else if (notif.type == 'TRANSACTION_COMPLETED' || notif.type == 'ITEM_SOLD') {
      final orderId = notif.orderId ?? notif.targetId;
      if (orderId != null && orderId.isNotEmpty) {
        context.push('/my-listings/sale-summary/$orderId');
        return;
      }
      context.push(AppRoutes.myListings);
    } else if (notif.type == 'OFFER_ACCEPTED') {
      final listingId = notif.listingId ?? notif.targetId;
      if (listingId != null && listingId.isNotEmpty) {
        context.push('/chat/offer/$listingId');
        return;
      }
      context.push(AppRoutes.chatList);
    } else if (notif.type == 'BID') {
      context.push(AppRoutes.home);
    } else if (notif.type == 'SHIPPED' || notif.type == 'DELIVERED') {
      context.push(AppRoutes.orders);
    } else {
      context.push(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationsProvider);
    final unreadCount = notifState.unreadCount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Notification',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF004E54),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppTheme.border.withValues(alpha: 0.7),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle: "X unread"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Text(
                '$unreadCount unread',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),

            // Notification Cards List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: notifState.notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) {
                  final notif = notifState.notifications[idx];

                  return InkWell(
                    onTap: () => _handleNotificationTap(context, ref, notif),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon / Thumbnail Box
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F4F2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Icon(
                                    notif.type == 'OFFER' || notif.type == 'NEW_OFFER'
                                        ? Icons.local_offer_outlined
                                        : (notif.type == 'BID'
                                            ? Icons.gavel_rounded
                                            : (notif.type == 'SHIPPED'
                                                ? Icons.local_shipping_outlined
                                                : (notif.type == 'MEETUP_SCHEDULED'
                                                    ? Icons.handshake_outlined
                                                    : Icons.check_circle_outline_rounded))),
                                    color: const Color(0xFF004E54),
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Title & Body
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notif.title,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      notif.body,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.timeAgo,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Unread Dot Indicator
                              if (notif.isUnread)
                                Container(
                                  width: 9,
                                  height: 9,
                                  margin: const EdgeInsets.only(top: 4, left: 4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF004E54),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),

                          // Action Button if present
                          if (notif.actionLabel != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton(
                                onPressed: () => _handleNotificationTap(context, ref, notif),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF004E54),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  notif.actionLabel!,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
