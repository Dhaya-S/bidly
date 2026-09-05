import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../models/community_model.dart';
import '../providers/community_provider.dart';
import '../../sell/providers/sell_provider.dart';
import 'manage_community_screen.dart';
import 'community_reels_screen.dart';

class CommunityDetailScreen extends ConsumerStatefulWidget {
  final CommunityModel community;

  const CommunityDetailScreen({
    super.key,
    required this.community,
  });

  @override
  ConsumerState<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  final List<Map<String, dynamic>> _communityPosts = [];
  bool _isNotificationMuted = false;

  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(communityProvider.notifier).fetchMembers(widget.community.id);
      _loadRealPosts();
    });
  }

  Future<void> _loadRealPosts() async {
    setState(() => _isLoadingPosts = true);
    final posts = await ref.read(communityProvider.notifier).fetchCommunityPosts(widget.community.id);
    if (mounted) {
      setState(() {
        _communityPosts.clear();
        _communityPosts.addAll(posts);
        _isLoadingPosts = false;
      });
    }
  }

  void _confirmLeaveCommunity(CommunityModel community) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Leave Community',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to leave ${community.name}? You will no longer have access to this community\'s member feed and private listings.',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13.5, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              final success = await ref.read(communityProvider.notifier).leaveCommunity(community.id);
              if (success) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('You have left ${community.name}'),
                    backgroundColor: const Color(0xFF004E54),
                  ),
                );
                nav.pop();
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Failed to leave community. Community creators cannot leave their own community.'),
                    backgroundColor: Color(0xFFE11D48),
                  ),
                );
              }
            },
            child: const Text('Leave', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }





  void _showContactSheet(String sellerName, String productTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F4F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF004E54)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact $sellerName',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'About: $productTitle',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF004E54)),
              title: const Text('Chat on Bidly', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.chatList);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined, color: Color(0xFF004E54)),
              title: const Text('Call Seller', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling $sellerName...')),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _navigateToSell(CommunityModel comm) {
    ref.read(sellProvider.notifier).initForCommunity(
      communityId: comm.id,
      communityName: comm.name,
    );
    context.push(AppRoutes.sell);
  }

  @override
  Widget build(BuildContext context) {
    final commState = ref.watch(communityProvider);
    final match = commState.communities.firstWhere(
      (c) => c.id == widget.community.id,
      orElse: () => widget.community,
    );
    final community = match;
    final isAdmin = community.isAdmin || community.userRole == 'ADMIN';
    final isJoined = community.isJoined || isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E232A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ManageCommunityScreen(community: community),
              ),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F4F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_rounded, color: Color(0xFF004E54), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E232A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${community.membersCount > 0 ? community.membersCount : 1} members',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Join Button / Joined Badge / Admin Badge
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: isJoined
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4F1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isAdmin ? 'Admin' : 'Joined',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF004E54),
                        ),
                      ),
                    )
                  : InkWell(
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await ref.read(communityProvider.notifier).joinCommunity(community.id);
                        if (mounted && ok) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Joined ${community.name}! Added to your Communities.'),
                              backgroundColor: const Color(0xFF004E54),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF004E54),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Join',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline_rounded, color: Color(0xFF1E232A), size: 22),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ManageCommunityScreen(community: community),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isNotificationMuted ? Icons.notifications_off_outlined : Icons.notifications_none_rounded,
              color: const Color(0xFF1E232A),
              size: 22,
            ),
            onPressed: () {
              setState(() => _isNotificationMuted = !_isNotificationMuted);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isNotificationMuted ? 'Daily notifications muted' : 'Daily notifications enabled for ${community.name}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF1E232A), size: 22),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) {
              if (val == 'manage') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ManageCommunityScreen(community: community),
                  ),
                );
              } else if (val == 'add_post') {
                if (isJoined) {
                  _navigateToSell(community);
                } else {
                  _showJoinToInteractModal(community);
                }
              } else if (val == 'leave') {
                _confirmLeaveCommunity(community);
              } else if (val == 'rules') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Community Rules'),
                    content: Text(community.rules?.isNotEmpty == true ? community.rules! : '1. Be respectful\n2. No spam\n3. Genuine items only'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                    ],
                  ),
                );
              } else if (val == 'share') {
                Share.share('Join ${community.name} on Bidly: Find trusted local deals!');
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'manage',
                child: Row(
                  children: [
                    Icon(Icons.manage_accounts_outlined, size: 18, color: Color(0xFF004E54)),
                    SizedBox(width: 10),
                    Text('Manage Community'),
                  ],
                ),
              ),
              if (isJoined)
                const PopupMenuItem(
                  value: 'add_post',
                  child: Row(
                    children: [
                      Icon(Icons.post_add_rounded, size: 18, color: Color(0xFF004E54)),
                      SizedBox(width: 10),
                      Text('Post in Community'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'rules',
                child: Row(
                  children: [
                    Icon(Icons.rule_folder_outlined, size: 18, color: Color(0xFF004E54)),
                    SizedBox(width: 10),
                    Text('Rules & Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 18, color: Color(0xFF004E54)),
                    SizedBox(width: 10),
                    Text('Share Community'),
                  ],
                ),
              ),
              if (isJoined && !isAdmin)
                const PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app_rounded, size: 18, color: Color(0xFFE11D48)),
                      SizedBox(width: 10),
                      Text('Leave Community', style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: SafeArea(
        child: _isLoadingPosts
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF004E54)))
            : _communityPosts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE6F4F1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_outlined, color: Color(0xFF004E54), size: 32),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items in ${widget.community.name} yet',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E232A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isJoined
                                ? 'Be the first to post something in this community!'
                                : 'Join this community to see and post items.',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (!isJoined) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final ok = await ref.read(communityProvider.notifier).joinCommunity(community.id);
                                if (mounted && ok) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Welcome to ${community.name}!'), backgroundColor: const Color(0xFF004E54)),
                                  );
                                  _loadRealPosts();
                                }
                              },
                              icon: const Icon(Icons.group_add_rounded, size: 18),
                              label: const Text('Join Community', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF004E54),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                          if (isJoined) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _navigateToSell(community),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Post First Item', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF004E54),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF004E54),
                    onRefresh: _loadRealPosts,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 88),
                      itemCount: _communityPosts.length,
                      itemBuilder: (context, index) {
                        final post = _communityPosts[index];
                        return _buildPostCard(post, isJoined: isJoined, community: community);
                      },
                    ),
                  ),
      ),

      // Floating Action Button shown to all community members
      floatingActionButton: isJoined
          ? FloatingActionButton(
              onPressed: () => _navigateToSell(community),
              backgroundColor: const Color(0xFF004E54),
              elevation: 4,
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  void _showJoinToInteractModal(CommunityModel community) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48, height: 48,
              decoration: const BoxDecoration(color: Color(0xFFE6F4F1), shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF004E54), size: 26),
            ),
            const SizedBox(height: 16),
            const Text(
              'Members Only',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E232A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Join ${community.name} to make offers, bid, and contact sellers.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13.5, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.group_add_rounded, color: Colors.white, size: 20),
                label: const Text('Join Community', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004E54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await ref.read(communityProvider.notifier).joinCommunity(community.id);
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Welcome to ${community.name}!'), backgroundColor: const Color(0xFF004E54)),
                    );
                    ref.read(communityProvider.notifier).fetchMembers(community.id);
                    _loadRealPosts();
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Not now', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF64748B))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, {required bool isJoined, required CommunityModel community}) {
    final isAuction = post['sellingMethod'] == 'AUCTION';
    final isLiked = post['isLiked'] as bool? ?? false;
    final likesCount = post['likesCount'] as int? ?? 0;
    final sharesCount = post['sharesCount'] as int? ?? 0;
    final title = post['title'] as String? ?? '';
    final priceText = post['priceText'] as String? ?? '';
    final description = post['description'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Author Header
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F4F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, color: Color(0xFF004E54), size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['authorName'] as String,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E232A),
                        ),
                      ),
                      Text(
                        post['timeAgo'] as String,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isAuction ? const Color(0xFFFEF2F2) : const Color(0xFFE6F4F1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAuction ? 'AUCTION' : 'DIRECT',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isAuction ? const Color(0xFFEF4444) : const Color(0xFF004E54),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Product Image Preview (tap to open Reels)
          GestureDetector(
            onTap: () {
              final currentIndex = _communityPosts.indexOf(post);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CommunityReelsScreen(
                    community: widget.community,
                    posts: _communityPosts,
                    initialIndex: currentIndex >= 0 ? currentIndex : 0,
                  ),
                ),
              );
            },
            child: ClipRRect(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  (post['imageUrl'] != null && (post['imageUrl'] as String).isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: ApiClient.resolveMediaUrl(post['imageUrl'] as String),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 200,
                            color: const Color(0xFFE2F3F0),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF004E54),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            color: const Color(0xFFE2F3F0),
                            child: const Center(
                              child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF004E54), size: 36),
                            ),
                          ),
                        )
                      : Container(
                          height: 200,
                          width: double.infinity,
                          color: const Color(0xFFE2F3F0),
                          child: const Center(
                            child: Icon(Icons.image_outlined, color: Color(0xFF004E54), size: 40),
                          ),
                        ),
                  // Play icon overlay (to indicate tapping opens reels)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
          ),

          // 3. Product Info
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E232A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (priceText.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    priceText,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isAuction ? const Color(0xFFEF4444) : const Color(0xFF004E54),
                    ),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),

                // 4. Action Row (Likes, Share, Contact)
                Row(
                  children: [
                    // Left side: Like + Share (takes remaining space)
                    Expanded(
                      child: Row(
                        children: [
                          // Like Button — wired to backend
                          GestureDetector(
                            onTap: () async {
                              // Optimistic update
                              setState(() {
                                post['isLiked'] = !isLiked;
                                post['likesCount'] = isLiked ? (likesCount - 1) : (likesCount + 1);
                              });
                              // Call backend
                              final result = await ref.read(communityProvider.notifier).likePost(post['id'] as String);
                              if (result == null && mounted) {
                                // Revert on failure
                                setState(() {
                                  post['isLiked'] = isLiked;
                                  post['likesCount'] = likesCount;
                                });
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: isLiked ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                  size: 19,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  likesCount.toString(),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),

                          // Share Button — wired to backend
                          GestureDetector(
                            onTap: () async {
                              // Increment share count on backend
                              final newCount = await ref.read(communityProvider.notifier).sharePost(post['id'] as String);
                              if (newCount != null && mounted) {
                                setState(() {
                                  post['sharesCount'] = newCount;
                                });
                              }
                              // Open system share sheet
                              final shareText = priceText.isNotEmpty
                                  ? '$title — $priceText on Bidly Community'
                                  : '$title on Bidly Community';
                              Share.share(shareText);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.share_outlined, color: Color(0xFF64748B), size: 19),
                                const SizedBox(width: 5),
                                Text(
                                  sharesCount > 0 ? sharesCount.toString() : 'Share',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right side: Contact Button
                    InkWell(
                      onTap: () {
                        if (isJoined) {
                          _showContactSheet(post['authorName'] as String, title);
                        } else {
                          _showJoinToInteractModal(community);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF004E54),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Contact',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12.5,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}


