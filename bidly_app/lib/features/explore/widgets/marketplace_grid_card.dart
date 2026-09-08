import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_theme.dart';
import '../models/listing_model.dart';
import '../providers/explore_provider.dart';

class MarketplaceGridCard extends ConsumerStatefulWidget {
  final ListingModel listing;

  const MarketplaceGridCard({
    super.key,
    required this.listing,
  });

  @override
  ConsumerState<MarketplaceGridCard> createState() => _MarketplaceGridCardState();
}

class _MarketplaceGridCardState extends ConsumerState<MarketplaceGridCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
  }

  void _onLikeTapped() {
    _animController.forward(from: 0.0).then((_) {
      if (mounted) _animController.reverse();
    });
    ref.read(exploreProvider.notifier).toggleLike(widget.listing.id);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final isAuction = listing.isAuction;
    final isLiked = listing.isWishlisted;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              // Image Stack with Badges & Like Button
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: listing.primaryImageUrl != null && listing.primaryImageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ApiClient.resolveMediaUrl(listing.primaryImageUrl!),
                            height: 116,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            memCacheWidth: 380,
                            memCacheHeight: 380,
                            maxWidthDiskCache: 500,
                            maxHeightDiskCache: 500,
                            placeholder: (_, __) => Container(
                              height: 116,
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 1.8, color: AppTheme.primary),
                                ),
                              ),
                            ),
                            errorWidget: (ctx, url, error) => Container(
                              height: 116,
                              color: const Color(0xFFEDF5F5),
                              child: const Center(
                                child: Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8), size: 26),
                              ),
                            ),
                          )
                        : Container(
                            height: 116,
                            color: const Color(0xFFEDF5F5),
                            child: const Center(
                              child: Icon(Icons.image_outlined, color: AppTheme.primary, size: 28),
                            ),
                          ),
                  ),

                  // Top-Left Selling Type Badge: BIDDING or DIRECT BUY
                  Positioned(
                    top: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isAuction ? const Color(0xFFEF4444) : const Color(0xFF004E54),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          )
                        ],
                      ),
                      child: Text(
                        isAuction ? 'BIDDING' : 'DIRECT BUY',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // Top-Right Interactive Wishlist Heart Button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: _onLikeTapped,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ],
                        ),
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Icon(
                            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 15,
                            color: isLiked ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom-Left Location / Distance Chip
                  Positioned(
                    bottom: 5,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.58),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 9, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            listing.formattedDistance,
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

                  // Bottom-Right Reel Video Indicator
                  if (listing.reelUrl != null && listing.reelUrl!.trim().isNotEmpty)
                    Positioned(
                      bottom: 5,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 10),
                            SizedBox(width: 2),
                            Text(
                              'Reel',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Product Info Body (Compact & overflow-safe)
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
                    const SizedBox(height: 4),

                    // Location & Rating Row
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
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 1),
                        Text(
                          listing.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Condition Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        listing.formattedCondition,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
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
