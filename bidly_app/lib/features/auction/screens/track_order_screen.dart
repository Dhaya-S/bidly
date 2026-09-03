import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_theme.dart';
import '../providers/order_provider.dart';

class TrackOrderScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final String? listingId;

  const TrackOrderScreen({
    super.key,
    this.orderId,
    this.listingId,
  });

  @override
  ConsumerState<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends ConsumerState<TrackOrderScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(orderProvider.notifier);
      if (widget.orderId != null) {
        notifier.fetchOrder(widget.orderId!);
      } else if (widget.listingId != null) {
        notifier.fetchOrderByListing(widget.listingId!);
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    final order = ref.read(orderProvider).order;
    if (order == null) return;
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit OTP code')),
      );
      return;
    }

    final success = await ref.read(orderProvider.notifier).verifyMeetupOtp(order.id, otp);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Handover confirmed! Payment released to seller.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      context.pushReplacement('/orders/${order.id}/delivery-confirmation');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final order = state.order;

    if (state.isLoading && order == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF004E54))),
      );
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Order')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final isDelivered = order.status == 'DELIVERED';
    final isMeetup = order.isMeetup;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMeetup ? 'Meetup Order' : 'Track Order',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            Text(
              '#${order.orderNumber}',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDelivered
                  ? const Color(0xFFDCFCE7)
                  : (isMeetup ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isDelivered ? 'Handover Complete' : (isMeetup ? 'Meetup Scheduled' : 'In Transit'),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDelivered
                    ? const Color(0xFF15803D)
                    : (isMeetup ? const Color(0xFFB45309) : const Color(0xFF0369A1)),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Product Summary Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF004E54), size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.productTitle,
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Agreed for ${currencyFormatter.format(order.wonAmount)}',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF004E54)),
                            ),
                            const SizedBox(height: 2),
                            Text('Seller: ${order.sellerName}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Meetup Card or Courier Shipping Info Card
                if (isMeetup) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF004E54).withValues(alpha: 0.2), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.handshake_outlined, color: Color(0xFF004E54), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'In-Person Meetup',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF004E54)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                order.meetupLocation ?? 'Location to be coordinated',
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E232A)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // OTP Section (Shown to Buyer to share with Seller)
                        if (!order.isSeller && !isDelivered) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4F1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Your Handover Verification OTP',
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF004E54)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  order.meetupOtp ?? '••••••',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 6,
                                    color: Color(0xFF004E54),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Share this OTP with the seller only after inspecting and receiving the item.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ] else if (order.isSeller && !isDelivered) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Enter 6-Digit Seller OTP',
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E232A)),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Inspect the product in person, then enter the OTP shown by the seller.',
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _otpController,
                                        keyboardType: TextInputType.number,
                                        maxLength: 6,
                                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 4),
                                        decoration: InputDecoration(
                                          counterText: '',
                                          hintText: '000000',
                                          hintStyle: const TextStyle(color: Color(0xFFCBD5E1), letterSpacing: 4),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: state.isLoading ? null : _verifyOtp,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF004E54),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: state.isLoading
                                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                          : const Text('Verify', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Handover verified via OTP. Escrow released to seller.',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_shipping_outlined, color: Color(0xFF004E54), size: 20),
                                const SizedBox(width: 8),
                                Text(order.courierPartner, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            Text(
                              order.trackingNumber != null && order.trackingNumber!.isNotEmpty
                                  ? order.trackingNumber!
                                  : 'Tracking pending',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'BIDLY partners with verified couriers with door-to-door tracking and secure handling.',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // 3. Delivery Progress Timeline
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Progress',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 14),
                      if (order.trackingTimeline.isNotEmpty)
                        ...order.trackingTimeline.map((e) => _buildTimelineStep(
                              e.title,
                              e.description ?? '',
                              e.formattedTime,
                              isCompleted: e.isCompleted,
                            ))
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Tracking updates will appear as your shipment progresses.',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Delivery Address
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: Color(0xFF004E54), size: 18),
                          SizedBox(width: 6),
                          Text('Delivering To', style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(order.deliveryAddressFullName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        '${order.deliveryAddressLine}, ${order.deliveryAddressCity} - ${order.deliveryAddressPincode}',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      if (order.deliveryAddressPhone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('Phone: ${order.deliveryAddressPhone}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF94A3B8))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Seller Support Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF004E54),
                        child: Text(
                          order.sellerName.isNotEmpty ? order.sellerName.substring(0, order.sellerName.length >= 2 ? 2 : 1).toUpperCase() : '?',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.sellerName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700)),
                            Text('⭐ ${order.sellerRating} (${order.sellerSalesCount} sales)', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          context.push('/chat/${order.sellerId}?listingId=${order.listingId}');
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF004E54)),
                        label: const Text('Chat', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF004E54))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF004E54)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Action: [ Confirm Delivery Received ]
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/orders/${order.id}/delivery-confirmation');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDelivered ? const Color(0xFF004E54) : const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isDelivered ? 'View Delivery & Review' : '✓ Confirm Delivery Received',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String title, String subtitle, String time, {bool isCompleted = true, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: isCompleted ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            if (!isLast)
              Container(width: 2, height: 32, color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  Text(time, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
              const SizedBox(height: 1),
              Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}
