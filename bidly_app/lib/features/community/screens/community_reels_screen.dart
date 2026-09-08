import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../core/api/api_client.dart';
import '../models/community_model.dart';
import '../providers/community_provider.dart';

class CommunityReelsScreen extends ConsumerStatefulWidget {
  final CommunityModel community;
  final List<Map<String, dynamic>> posts;
  final int initialIndex;

  const CommunityReelsScreen({
    super.key,
    required this.community,
    required this.posts,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<CommunityReelsScreen> createState() =>
      _CommunityReelsScreenState();
}

class _CommunityReelsScreenState extends ConsumerState<CommunityReelsScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  final Map<int, VideoPlayerController> _videoControllers = {};
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initVideoFor(_currentIndex);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _videoControllers[_currentIndex]?.pause();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    for (final ctrl in _videoControllers.values) {
      ctrl.pause();
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _initVideoFor(int index) async {
    if (index < 0 || index >= widget.posts.length) return;
    final post = widget.posts[index];
    String? videoUrl = post['videoUrl'] as String? ?? post['reelUrl'] as String?;
    if (videoUrl == null || videoUrl.isEmpty) {
      final mediaItems = post['mediaItems'] as List?;
      if (mediaItems != null) {
        for (final item in mediaItems) {
          if (item is Map && (item['type'] == 'VIDEO' || item['type']?.toString().toUpperCase() == 'VIDEO')) {
            videoUrl = item['url']?.toString();
            if (videoUrl != null && videoUrl.isNotEmpty) break;
          }
        }
      }
    }
    if (videoUrl == null || videoUrl.isEmpty) return;
    if (_videoControllers.containsKey(index)) return;

    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _videoControllers[index] = ctrl;
      await ctrl.initialize();
      if (mounted && _currentIndex == index) {
        ctrl.setLooping(true);
        if (ModalRoute.of(context)?.isCurrent == true) {
          ctrl.play();
        } else {
          ctrl.pause();
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[CommunityReelsScreen] Error initializing video: $e');
    }
  }

  void _onPageChanged(int index) {
    // Pause previous
    _videoControllers[_currentIndex]?.pause();

    setState(() => _currentIndex = index);

    // Play new
    final ctrl = _videoControllers[index];
    if (ctrl != null && ctrl.value.isInitialized) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        ctrl.play();
      } else {
        ctrl.pause();
      }
    } else {
      _initVideoFor(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: widget.posts.length,
            itemBuilder: (context, index) {
              return _buildReelItem(widget.posts[index], index);
            },
          ),

          // Top overlay: back + community name
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _videoControllers[_currentIndex]?.pause();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.community.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.posts.length} posts',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scroll indicator dots on right side
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.posts.length > 7 ? 7 : widget.posts.length, (i) {
                  final actualI = widget.posts.length > 7
                      ? (i * (widget.posts.length / 7)).round()
                      : i;
                  final isActive = actualI == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    width: isActive ? 6 : 4,
                    height: isActive ? 20 : 8,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelItem(Map<String, dynamic> post, int index) {
    final imageUrl = post['imageUrl'] as String?;
    final title = post['title'] as String? ?? '';
    final priceText = post['priceText'] as String? ?? '';
    final authorName = post['authorName'] as String? ?? 'Member';
    final isAuction = post['sellingMethod'] == 'AUCTION';
    final isLiked = post['isLiked'] as bool? ?? false;
    final likesCount = post['likesCount'] as int? ?? 0;
    final sharesCount = post['sharesCount'] as int? ?? 0;

    final videoCtrl = _videoControllers[index];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background: video or image
        if (videoCtrl != null && videoCtrl.value.isInitialized)
          GestureDetector(
            onTap: () {
              if (videoCtrl.value.isPlaying) {
                videoCtrl.pause();
              } else {
                videoCtrl.play();
              }
              setState(() {});
            },
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: videoCtrl.value.size.width,
                height: videoCtrl.value.size.height,
                child: VideoPlayer(videoCtrl),
              ),
            ),
          )
        else if (imageUrl != null && imageUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: ApiClient.resolveMediaUrl(imageUrl),
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: const Color(0xFF1A1A2E)),
            errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1A2E)),
          )
        else
          Container(
            color: const Color(0xFF1A1A2E),
            child: const Center(
              child: Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 64),
            ),
          ),

        // Dark gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom info overlay
        Positioned(
          bottom: 48,
          left: 16,
          right: 72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author row
              Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(color: Color(0xFF004E54), shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    authorName,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isAuction ? const Color(0xFFEF4444) : const Color(0xFF004E54),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAuction ? 'AUCTION' : 'DIRECT',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Title
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              // Price
              if (priceText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    priceText,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isAuction ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Right side action buttons
        Positioned(
          right: 12,
          bottom: 80,
          child: Column(
            children: [
              // Like
              _ReelActionButton(
                icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                iconColor: isLiked ? const Color(0xFFEF4444) : Colors.white,
                label: likesCount.toString(),
                onTap: () async {
                  final nextLiked = !isLiked;
                  if (nextLiked) {
                    HapticFeedback.mediumImpact();
                  } else {
                    HapticFeedback.lightImpact();
                  }
                  setState(() {
                    post['isLiked'] = nextLiked;
                    post['likesCount'] = nextLiked ? (likesCount + 1) : (likesCount > 0 ? likesCount - 1 : 0);
                  });
                  final data = await ref.read(communityProvider.notifier).likePost(
                    post['id'] as String,
                    action: nextLiked ? 'like' : 'unlike',
                  );
                  if (data != null && mounted) {
                    setState(() {
                      if (data['liked'] != null) post['isLiked'] = data['liked'];
                      if (data['likesCount'] != null) post['likesCount'] = data['likesCount'];
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Share
              _ReelActionButton(
                icon: Icons.share_outlined,
                iconColor: Colors.white,
                label: sharesCount > 0 ? sharesCount.toString() : 'Share',
                onTap: () async {
                  _videoControllers[_currentIndex]?.pause();
                  if (mounted) setState(() {});
                  final count = await ref.read(communityProvider.notifier).sharePost(post['id'] as String);
                  if (count != null && mounted) {
                    setState(() => post['sharesCount'] = count);
                  }
                },
              ),
              const SizedBox(height: 20),

              // Pause/Play indicator
              if (videoCtrl != null && videoCtrl.value.isInitialized)
                _ReelActionButton(
                  icon: videoCtrl.value.isPlaying ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                  iconColor: Colors.white,
                  label: '',
                  onTap: () {
                    if (videoCtrl.value.isPlaying) {
                      videoCtrl.pause();
                    } else {
                      videoCtrl.play();
                    }
                    setState(() {});
                  },
                ),
            ],
          ),
        ),

        // Page indicator
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '${index + 1} / ${widget.posts.length}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReelActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ReelActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
