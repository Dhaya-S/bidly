import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    if (!widget.post.isLikedByMe) {
      ref.read(postsProvider.notifier).toggleLike(widget.post.id);
    }
    setState(() => _showHeartBurst = true);
    _heartAnimController.forward(from: 0.0);
  }

  String _formatTag(String tag) {
    switch (tag.toUpperCase()) {
      case 'SELLING':
      case 'DIRECT':
        return 'Direct Buy';
      case 'AUCTION':
        return 'Live Auction';
      case 'ANNOUNCEMENT':
        return 'Announcement';
      case 'REVIEW':
        return 'Review';
      default:
        return tag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final mediaList = post.mediaItems;
    final hasMultipleMedia = mediaList.length > 1;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. HEADER ROW (Avatar, Name, Community, Time, Tag, Menu) ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: post.avatarBgColor,
                  backgroundImage: post.authorAvatarUrl != null
                      ? CachedNetworkImageProvider(ApiClient.resolveMediaUrl(post.authorAvatarUrl!))
                      : null,
                  child: post.authorAvatarUrl == null
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
                const SizedBox(width: 12),

                // Name, Community, Time & Tag Pill
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                                children: [
                                  TextSpan(text: post.authorName),
                                  if (post.communityName != null && post.communityName!.isNotEmpty) ...[
                                    const TextSpan(
                                      text: '  ·  ',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    TextSpan(
                                      text: post.communityName!,
                                      style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            post.timeAgo,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textHint,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: post.tagColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: post.tagColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _formatTag(post.tag),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: post.tagColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Three-dot menu
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppTheme.textHint,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showMoreOptions(context),
                ),
              ],
            ),
          ),

          // ─── 2. POST TEXT CONTENT ───
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
              child: Text(
                post.content,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textPrimary,
                  height: 1.45,
                ),
              ),
            ),

          // ─── 3. INSTAGRAM-STYLE MEDIA CAROUSEL (Images + Videos) ───
          if (mediaList.isNotEmpty)
            Container(
              height: 340,
              width: double.infinity,
              color: Colors.black,
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

                  // Floating Instagram-style Page Indicator ("1 / 4")
                  if (hasMultipleMedia)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: Text(
                          '${_currentMediaIndex + 1} / ${mediaList.length}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                  // Animated Double-Tap Heart Burst Overlay
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
                                  size: 96,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Bottom Dots Indicator (Instagram style)
                  if (hasMultipleMedia)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(mediaList.length, (dotIdx) {
                          final isSelected = dotIdx == _currentMediaIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isSelected ? 8 : 6,
                            height: isSelected ? 8 : 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? const Color(0xFF2DD4BF) : Colors.white.withValues(alpha: 0.5),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF2DD4BF).withValues(alpha: 0.6),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            )
          else if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty)
            GestureDetector(
              onDoubleTap: _triggerDoubleTapHeart,
              child: SizedBox(
                height: 320,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: ApiClient.resolveMediaUrl(post.mediaUrl!),
                  width: double.infinity,
                  height: 320,
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
                ),
              ),
            ),

          // ─── 4. LINKED PRODUCT CTA BAR (Direct Buy vs Auction Card) ───
          if (post.listingId != null || post.price != null || post.isAuction)
            _buildProductActionBar(context, post),

          // ─── 5. ENGAGEMENT FOOTER (Likes & Shares) ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // Like Button & Count
                GestureDetector(
                  onTap: () => ref.read(postsProvider.notifier).toggleLike(post.id),
                  child: Row(
                    children: [
                      AnimatedScale(
                        scale: post.isLikedByMe ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.elasticOut,
                        child: Icon(
                          post.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: post.isLikedByMe ? AppTheme.error : AppTheme.textSecondary,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likesCount}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: post.isLikedByMe ? AppTheme.error : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Share Button & Count
                GestureDetector(
                  onTap: () {
                    ref.read(postsProvider.notifier).sharePost(post.id);
                    Share.share('${post.content}\n\nShared via Bidly Marketplace');
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.share_outlined,
                        color: AppTheme.textSecondary,
                        size: 21,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.sharesCount}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Tag indicator pill on right
                if (post.listingId != null)
                  TextButton.icon(
                    onPressed: () => context.push('/listing/${post.listingId}'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.primary),
                    label: const Text(
                      'View Product',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),

          // Card Divider
          Container(
            height: 8,
            color: AppTheme.surfaceVariant,
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
              bottom: 14,
              right: 14,
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

  Widget _buildProductActionBar(BuildContext context, PostModel post) {
    final isAuction = post.isAuction;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Price / Current Bid Display
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAuction ? 'CURRENT BID' : 'PRICE',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                post.formattedPrice,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isAuction ? const Color(0xFF004E54) : AppTheme.primary,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Auction / Direct Buy Action Button
          if (post.listingId != null)
            ElevatedButton(
              onPressed: () => context.push('/listing/${post.listingId}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAuction ? const Color(0xFF004E54) : AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text(
                isAuction ? 'Bid Now' : 'Make Offer / Buy',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
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
                Share.share('${widget.post.content}\n\nShared via Bidly');
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
