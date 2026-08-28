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
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/listing/${listing.id}', extra: listing),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: listing.primaryImageUrl != null && listing.primaryImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ApiClient.resolveMediaUrl(listing.primaryImageUrl!),
                          height: 64,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          memCacheWidth: 200,
                          memCacheHeight: 200,
                          placeholder: (_, __) => Container(color: const Color(0xFFF1F5F9)),
                          errorWidget: (_, __, ___) => Container(
                            height: 64,
                            color: const Color(0xFFEDF5F5),
                            child: const Center(
                              child: Icon(Icons.image_outlined, color: AppTheme.primary, size: 20),
                            ),
                          ),
                        )
                      : Container(
                          height: 64,
                          color: const Color(0xFFEDF5F5),
                          child: const Icon(Icons.image_outlined, color: AppTheme.primary, size: 20),
                        ),
                ),
                const SizedBox(height: 5),
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  listing.formattedPrice,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
