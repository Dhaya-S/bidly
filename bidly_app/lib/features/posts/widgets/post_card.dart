import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_theme.dart';
import '../../explore/models/listing_model.dart';
import '../models/post_model.dart';
import '../providers/posts_provider.dart';

class PostCard extends ConsumerStatefulWidget {
  final PostModel post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> with SingleTickerProviderStateMixin {
  int _currentMediaIndex = 0;
  late PageController _pageController;

  // Video playback lifecycle management
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isInitializingVideo = false;
  bool _isMuted = true;
  bool _showHeartBurst = false;

  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnim;
  late Animation<double> _heartOpacityAnim;

  @override
  void initState({Key? key}) {
    super.initState();
    _pageController = PageController();

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _heartScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInBack)), weight: 20),
    ]).animate(_heartAnimController);

    _heartOpacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartAnimController);

    _heartAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _showHeartBurst = false);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndInitVideoForSlide(0);
    });
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _disposeVideo();
      _currentMediaIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndInitVideoForSlide(0);
      });
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    _pageController.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  void _disposeVideo() {
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.dispose();
      _videoController = null;
      _isVideoInitialized = false;
      _isInitializingVideo = false;
    }
  }

  void _checkAndInitVideoForSlide(int index) {
    if (widget.post.mediaItems.isEmpty || index >= widget.post.mediaItems.length) {
      _disposeVideo();
      return;
    }

    final item = widget.post.mediaItems[index];
    if (item.type == 'VIDEO' && item.url.isNotEmpty) {
      _initializeVideo(item.url);
    } else {
      _disposeVideo();
    }
  }

  Future<void> _initializeVideo(String url) async {
    _disposeVideo();
    if (!mounted) return;

    setState(() => _isInitializingVideo = true);

    try {
      final resolvedUrl = ApiClient.resolveMediaUrl(url);
      final controller = VideoPlayerController.networkUrl(Uri.parse(resolvedUrl));
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.setLooping(true);
      controller.setVolume(_isMuted ? 0.0 : 1.0);
      controller.play();

      setState(() {
        _videoController = controller;
        _isVideoInitialized = true;
        _isInitializingVideo = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitializingVideo = false;
          _isVideoInitialized = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController != null && _isVideoInitialized) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
      });
    }
  }

  void _toggleMute() {
    if (_videoController != null && _isVideoInitialized) {
      final newMuted = !_isMuted;
      _videoController!.setVolume(newMuted ? 0.0 : 1.0);
      setState(() => _isMuted = newMuted);
    }
  }

  void _triggerDoubleTapHeart() {
    final isCurrentlyLiked = ref.read(postsProvider).isLiked(widget.post.id, widget.post.isLikedByMe);
    if (!isCurrentlyLiked) {
      ref.read(postsProvider.notifier).toggleLike(
        widget.post.id,
        widget.post.likesCount,
        targetLiked: true,
        initialLiked: widget.post.isLikedByMe,
      );
    }
    setState(() => _showHeartBurst = true);
    _heartAnimController.forward(from: 0.0);
  }

  void _handleSingleTapLike() {
    final isCurrentlyLiked = ref.read(postsProvider).isLiked(widget.post.id, widget.post.isLikedByMe);
    if (!isCurrentlyLiked) {
      setState(() => _showHeartBurst = true);
      _heartAnimController.forward(from: 0.0);
    }
    ref.read(postsProvider.notifier).toggleLike(
      widget.post.id,
      widget.post.likesCount,
      initialLiked: widget.post.isLikedByMe,
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    num val = 0;
    if (amount is num) {
      val = amount;
    } else {
      val = num.tryParse(amount.toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    }
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0);
    return format.format(val).trim();
  }

  String _formatTimeRemaining(DateTime? auctionEndTime) {
    if (auctionEndTime == null) return '2h 14m';
    final diff = auctionEndTime.difference(DateTime.now());
    if (diff.isNegative) return 'Ended';
    if (diff.inDays > 0) {
      return '${diff.inDays}d ${diff.inHours % 24}h';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    }
    return '${diff.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    // In Posts section, show photo posts only (reels show in Feed section only)
    final imageItems = post.mediaItems
        .where((m) => m.type.toUpperCase() != 'VIDEO' && !m.url.contains('-thumb.jpg'))
        .toList();
    final mediaList = imageItems.isNotEmpty
        ? imageItems
        : (post.mediaUrl != null &&
                post.mediaUrl!.isNotEmpty &&
                post.mediaType.toUpperCase() != 'VIDEO' &&
                !post.mediaUrl!.contains('-thumb.jpg')
            ? [MediaItemModel(url: post.mediaUrl!, type: 'IMAGE', sortOrder: 0)]
            : <MediaItemModel>[]);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. AUTHOR ROW (Avatar, Name, Chevron, Trusted Badge, Time, Menu) ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Initials Circle Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF004E54),
                  backgroundImage: (post.authorAvatarUrl != null && post.authorAvatarUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(ApiClient.resolveMediaUrl(post.authorAvatarUrl!))
                      : null,
                  child: (post.authorAvatarUrl == null || post.authorAvatarUrl!.isEmpty)
                      ? Text(
                          post.initials,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),

                // Author Name + Chevron + Trusted Badge (Line 1) & Time Ago (Line 2)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.authorName,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),

                          // Dark Teal Trusted Badge matching screenshot
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF004E54),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_outlined, size: 11, color: Colors.white),
                                SizedBox(width: 3.5),
                                Text(
                                  'Trusted',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            post.timeAgo,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '·',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // More Options Menu
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Color(0xFF94A3B8),
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showMoreOptions(context),
                ),
              ],
            ),
          ),

          // ─── 2. SWIPABLE MEDIA (PageView, Badges, Heart Burst) ───
          if (mediaList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 260,
                  width: double.infinity,
                  color: const Color(0xFFF1F5F9),
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: mediaList.length,
                        onPageChanged: (idx) {
                          setState(() => _currentMediaIndex = idx);
                          _checkAndInitVideoForSlide(idx);
                        },
                        itemBuilder: (context, index) {
                          final item = mediaList[index];
                          return GestureDetector(
                            onDoubleTap: _triggerDoubleTapHeart,
                            child: _buildMediaSlide(item, index),
                          );
                        },
                      ),

                      // Animated Double Tap Heart Burst
                      if (_showHeartBurst)
                        Positioned.fill(
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _heartAnimController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _heartOpacityAnim.value,
                                  child: Transform.scale(
                                    scale: _heartScaleAnim.value,
                                    child: const Icon(
                                      Icons.favorite_rounded,
                                      color: Colors.white,
                                      size: 88,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                      // Top-Left Badge: DIRECT BUY (Teal) or BIDDING (Red)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: post.isAuction ? const Color(0xFFEF4444) : const Color(0xFF004E54),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            post.isAuction ? 'BIDDING' : 'DIRECT BUY',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      // Bottom-Left Badge: 📍 2.0 km (White Pill)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 13,
                                color: Color(0xFF1E293B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.distanceKm.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Multiple Media Indicator Dots
                      if (mediaList.length > 1)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentMediaIndex + 1}/${mediaList.length}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // ─── 3. PRODUCT INFO (Title, Description, Auction Card, Buttons, Footer) ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                if (post.displayTitle.isNotEmpty)
                  Text(
                    post.displayTitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                // Description
                if (post.displayDescription.isNotEmpty ||
                    (post.content.isNotEmpty && post.content.trim() != post.displayTitle.trim())) ...[
                  const SizedBox(height: 4),
                  Text(
                    post.displayDescription.isNotEmpty ? post.displayDescription : post.content,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                      height: 1.45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // 4. Dark Auction Card (Shown only for AUCTION posts)
                if (post.isAuction)
                  _buildAuctionInfoCard(post),

                // 5. Action Buttons (View Details + Make offer / Bid Now)
                Padding(
                  padding: const EdgeInsets.only(top: 14.0),
                  child: Row(
                    children: [
                      // View Details (Outlined Button)
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () {
                              if (post.listingId != null && post.listingId!.isNotEmpty) {
                                context.push('/listing/${post.listingId}');
                              } else {
                                _showDetailsBottomSheet(context, post);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.white,
                              elevation: 0,
                            ),
                            child: const Text(
                              'View Details',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Make offer (Direct Buy) or Bid Now (Auction)
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () {
                              if (post.listingId != null && post.listingId!.isNotEmpty) {
                                context.push('/listing/${post.listingId}');
                              } else {
                                _showDetailsBottomSheet(context, post);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: post.isAuction ? const Color(0xFFEF4444) : const Color(0xFF004E54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              post.isAuction ? 'Bid Now' : 'Make offer',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 6. Realtime Likes & Shares Footer
                Padding(
                  padding: const EdgeInsets.only(top: 14.0, bottom: 14.0),
                  child: Row(
                    children: [
                      // Like Button & Count (Targeted Reactive Subscription)
                      Consumer(
                        builder: (context, ref, _) {
                          final isLiked = ref.watch(postsProvider.select((s) => s.isLiked(post.id, post.isLikedByMe)));
                          final count = ref.watch(postsProvider.select((s) => s.likesCount(post.id, post.likesCount)));

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _handleSingleTapLike,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedScale(
                                  scale: isLiked ? 1.15 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.elasticOut,
                                  child: Icon(
                                    isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isLiked ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 24),

                      // Share Button & Count
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          ref.read(postsProvider.notifier).sharePost(post.id);
                          Share.share('${post.displayTitle}\n\nShared via Bidly Marketplace');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.share_outlined,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${post.sharesCount}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card Separation Band
          Container(
            height: 8,
            color: const Color(0xFFF1F5F9),
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionInfoCard(PostModel post) {
    final currentBidVal = post.currentBid ?? post.startingBid ?? post.price ?? 0;
    final currentBidFormatted = _formatCurrency(currentBidVal);
    final bidsCount = post.bidsCount;
    final timeRemaining = _formatTimeRemaining(post.auctionEndTime);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF5A6678),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current bid',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFCBD5E1),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '₹$currentBidFormatted',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$bidsCount bids placed',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      timeRemaining,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'remaining',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSlide(MediaItemModel item, int index) {
    if (item.type == 'VIDEO') {
      if (index == _currentMediaIndex && _videoController != null && _isVideoInitialized) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _videoController!.value.size.width > 0 ? _videoController!.value.size.width : 360,
                  height: _videoController!.value.size.height > 0 ? _videoController!.value.size.height : 640,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
            // Tap overlay to play/pause
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlayPause,
              child: Container(
                color: Colors.transparent,
                child: !_videoController!.value.isPlaying
                    ? Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            // Mute / Unmute Button
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        return Container(
          color: Colors.black,
          child: Center(
            child: _isInitializingVideo && index == _currentMediaIndex
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2DD4BF)),
                    ),
                  )
                : const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_outline_rounded, color: Colors.white70, size: 52),
                      SizedBox(height: 6),
                      Text(
                        'Video Reel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      }
    }

    // IMAGE SLIDE
    return CachedNetworkImage(
      imageUrl: ApiClient.resolveMediaUrl(item.url),
      fit: BoxFit.cover,
      memCacheWidth: 800,
      memCacheHeight: 800,
      maxWidthDiskCache: 1200,
      maxHeightDiskCache: 1200,
      placeholder: (context, url) => Container(
        color: AppTheme.surfaceVariant,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.primary,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppTheme.surfaceVariant,
        child: const Center(
          child: Icon(Icons.broken_image_rounded, color: AppTheme.textHint, size: 36),
        ),
      ),
    );
  }

  void _showDetailsBottomSheet(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                post.displayTitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004E54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: AppTheme.textPrimary),
              title: const Text('Share post', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                Share.share('${widget.post.displayTitle}\n\nShared via Bidly');
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppTheme.error),
              title: const Text('Report post', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppTheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post reported. Thank you for keeping Bidly safe.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
