import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_theme.dart';
import '../providers/auction_provider.dart';
import '../providers/order_provider.dart';

class AuctionWonScreen extends ConsumerStatefulWidget {
  final String listingId;

  const AuctionWonScreen({
    super.key,
    required this.listingId,
  });

  @override
  ConsumerState<AuctionWonScreen> createState() => _AuctionWonScreenState();
}

class _AuctionWonScreenState extends ConsumerState<AuctionWonScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auctionProvider.notifier).fetchAuctionDetails(widget.listingId);
      ref.read(orderProvider.notifier).fetchOrderByListing(widget.listingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auctionState = ref.watch(auctionProvider);
    final orderState = ref.watch(orderProvider);

    final details = auctionState.auctionDetails;
    final order = orderState.order;

    final wonPrice = order?.wonAmount ?? details?.currentHighestBid ?? 43500.0;
    final productTitle = order?.productTitle ?? details?.title ?? 'iPhone 13 Pro – 256GB';
    final sellerName = order?.sellerName ?? details?.sellerName ?? 'Tech Deals Chennai';
    final sellerRating = order?.sellerRating ?? details?.sellerRating ?? 4.9;
    final sellerReviews = details?.sellerReviewsCount ?? 312;

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
        title: const Text(
          'Auction Won',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Trophy / Confetti Header
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF86EFAC), width: 2),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF16A34A), size: 36),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Congratulations!',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                ),
                const Text(
                  'You Won the Auction!',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                ),
                const SizedBox(height: 4),
                Text(
                  productTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                // 2. Winning Bid Teal Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004E54),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Winning Bid',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF99F6E4), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormatter.format(wonPrice),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline, size: 14, color: Color(0xFF86EFAC)),
                            SizedBox(width: 6),
                            Text(
                              'Payment Secured in Escrow • Released after delivery',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFFCCFBF1), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Seller Card
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
                        radius: 22,
                        backgroundColor: const Color(0xFF004E54),
                        child: Text(
                          sellerName.isNotEmpty ? sellerName.substring(0, 2).toUpperCase() : 'TD',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sellerName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 4),
                                Text('$sellerRating • $sellerReviews reviews', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF64748B))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                        child: const Text('VERIFIED', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. "What Happens Next?" Stepper Card
                Container(
                  width: double.infinity,
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
                        'What Happens Next?',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 14),
                      _buildNextStep('1', 'Payment Moved to Escrow', 'Your reserved funds are now safely held in Escrow', isDone: true),
                      _buildNextStep('2', 'Chat with Seller', 'Coordinate dispatch or address verification directly', isCurrent: true),
                      _buildNextStep('3', 'Seller Ships Product', 'Track package via Ekart Logistics tracking number'),
                      _buildNextStep('4', 'Confirm Delivery', 'Inspect product and release escrow payout to seller', isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Buyer Protection Notice
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: Color(0xFF15803D), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'BIDLY Escrow Guarantee: If the item does not match description or isn\'t delivered, you receive a 100% full refund.',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF15803D), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Actions: [ 💬 Chat with Seller ] [ 📦 Track Order ]
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
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (details?.sellerId != null) {
                              context.push('/chat/${details!.sellerId}?listingId=${widget.listingId}');
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF004E54)),
                          label: const Text('Chat with Seller', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFF004E54))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF004E54), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push('/orders/listing/${widget.listingId}/track');
                          },
                          icon: const Icon(Icons.local_shipping_outlined, size: 18),
                          label: const Text('Track Order', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004E54),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStep(String number, String title, String subtitle, {bool isDone = false, bool isCurrent = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFF10B981) : (isCurrent ? const Color(0xFF004E54) : const Color(0xFFE2E8F0)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text(number, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w800, color: isCurrent ? Colors.white : const Color(0xFF64748B))),
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 28, color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 1),
              Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
