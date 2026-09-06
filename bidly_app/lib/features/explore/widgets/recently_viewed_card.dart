import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_theme.dart';
import '../models/listing_model.dart';

class RecentlyViewedCard extends StatelessWidget {
  final ListingModel listing;

  const RecentlyViewedCard({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/listing/${listing.id}', extra: listing),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Square Thumbnail (82x82)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 82,
                  width: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: listing.primaryImageUrl != null && listing.primaryImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ApiClient.resolveMediaUrl(listing.primaryImageUrl!),
                          height: 82,
                          width: 82,
                          fit: BoxFit.cover,
                          memCacheWidth: 200,
                          memCacheHeight: 200,
                          placeholder: (_, __) => Container(
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
                            color: const Color(0xFFEDF5F5),
                            child: const Center(
                              child: Icon(Icons.image_outlined, color: AppTheme.primary, size: 22),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFEDF5F5),
                          child: const Center(
                            child: Icon(Icons.image_outlined, color: AppTheme.primary, size: 22),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 5),

              // Title
              Text(
                listing.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),

              // Price
              Text(
                listing.formattedPrice,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF004E54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
