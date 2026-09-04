import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import 'reject_offer_bottom_sheet.dart';

class NewOfferBottomSheet extends StatelessWidget {
  final String offerId;
  final String listingId;
  final String? buyerId;
  final String buyerName;
  final String? buyerAvatarUrl;
  final String buyerLocality;
  final double offerAmount;
  final String productTitle;
  final double listingPrice;
  final VoidCallback? onOfferRejected;

  const NewOfferBottomSheet({
    super.key,
    required this.offerId,
    required this.listingId,
    this.buyerId,
    required this.buyerName,
    this.buyerAvatarUrl,
    this.buyerLocality = 'Nearby',
    required this.offerAmount,
    required this.productTitle,
    required this.listingPrice,
    this.onOfferRejected,
  });

  static Future<void> show(
    BuildContext context, {
    required String offerId,
    required String listingId,
    String? buyerId,
    required String buyerName,
    String? buyerAvatarUrl,
    String buyerLocality = 'Nearby',
    required double offerAmount,
    required String productTitle,
    required double listingPrice,
    VoidCallback? onOfferRejected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NewOfferBottomSheet(
        offerId: offerId,
        listingId: listingId,
        buyerId: buyerId,
        buyerName: buyerName,
        buyerAvatarUrl: buyerAvatarUrl,
        buyerLocality: buyerLocality,
        offerAmount: offerAmount,
        productTitle: productTitle,
        listingPrice: listingPrice,
        onOfferRejected: onOfferRejected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diff = listingPrice - offerAmount;
    final pct = listingPrice > 0 ? ((diff / listingPrice) * 100).round() : 0;
    final isBelow = diff > 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'New Offer',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Buyer & Offer Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE0F2F1),
                  backgroundImage: buyerAvatarUrl != null && buyerAvatarUrl!.isNotEmpty
                      ? NetworkImage(buyerAvatarUrl!)
                      : null,
                  child: (buyerAvatarUrl == null || buyerAvatarUrl!.isEmpty)
                      ? Text(
                          buyerName.isNotEmpty ? buyerName[0].toUpperCase() : 'B',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF004E54),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Name & Locality
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buyerName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            buyerLocality,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Offer Amount
                Text(
                  '₹${offerAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF004E54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Product Details
          Text(
            'Product: $productTitle',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your Price: ₹${listingPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Comparison Chip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF004E54)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isBelow
                        ? 'Offer is $pct% below your asking price. You can negotiate in chat.'
                        : 'Offer meets or exceeds your asking price!',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF004E54),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Continue to Chat Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(
                  '/chat/offer/$listingId',
                  extra: {
                    'buyerId': buyerId,
                    'offerId': offerId,
                    'buyerName': buyerName,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004E54),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue to Chat',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Reject Offer Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                RejectOfferBottomSheet.show(
                  context,
                  offerId: offerId,
                  onRejected: onOfferRejected,
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE53935)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Reject Offer',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
