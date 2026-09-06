import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_theme.dart';
import '../models/listing_model.dart';

class DealNearYouCard extends StatelessWidget {
  final ListingModel listing;

  const DealNearYouCard({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    final isAuction = listing.isAuction;

    return Container(
      width: 182,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/listing/${listing.id}', extra: listing),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Stack with Badges & Distance Overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: listing.primaryImageUrl != null && listing.primaryImageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ApiClient.resolveMediaUrl(listing.primaryImageUrl!),
                            height: 105,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            memCacheWidth: 380,
                            memCacheHeight: 380,
                            maxWidthDiskCache: 500,
                            maxHeightDiskCache: 500,
                            placeholder: (_, __) => Container(
                              height: 105,
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 1.8, color: AppTheme.primary),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              height: 105,
                              color: const Color(0xFFEDF5F5),
                              child: const Center(
                                child: Icon(Icons.image_outlined, color: AppTheme.primary, size: 26),
                              ),
                            ),
                          )
                        : Container(
                            height: 105,
                            color: const Color(0xFFEDF5F5),
                            child: const Center(
                              child: Icon(Icons.image_outlined, color: AppTheme.primary, size: 26),
                            ),
                          ),
                  ),

                  // Top-Left Badge: BIDDING (red) or DIRECT BUY (dark teal)
                  Positioned(
                    top: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAuction ? const Color(0xFFEF4444) : const Color(0xFF004E54),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        isAuction ? 'BIDDING' : 'DIRECT BUY',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // Bottom-Left Distance Overlay Pill: 📍 X.X km
                  Positioned(
                    bottom: 6,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 9, color: Colors.white),
                          const SizedBox(width: 2.5),
                          Text(
                            '${listing.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom-Right Reel Video Indicator (if available)
                  if (listing.reelUrl != null && listing.reelUrl!.trim().isNotEmpty)
                    Positioned(
                      bottom: 6,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 11),
                            SizedBox(width: 2),
                            Text(
                              'Reel',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Card Info & Action (Strictly bounded to prevent overflow)
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 6, 9, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Price
                    Text(
                      listing.formattedPrice,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Sub-info: Auction red timer (🕒 2h 14m) OR Direct Buy locality (📍 Adyar)
                    if (isAuction)
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFFEF4444)),
                          const SizedBox(width: 3),
                          Text(
                            listing.timeLeft,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 11, color: Color(0xFF64748B)),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              listing.locality ?? listing.city ?? 'Nearby',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),

                    // Full-width Action Button: Red "Bid Now" or Dark Teal "Make Offer"
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!isAuction) {
                            context.push('/chat/offer/${listing.id}', extra: listing);
                          } else {
                            context.push('/listing/${listing.id}', extra: listing);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAuction ? const Color(0xFFEF4444) : const Color(0xFF004E54),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isAuction ? 'Bid Now' : 'Make Offer',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
