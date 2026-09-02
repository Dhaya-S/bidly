import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import 'chat_detail_screen.dart';

class ChatThreadModel {
  final String id;
  final String userName;
  final String userRole; // 'Seller' | 'Buyer'
  final String productSubject;
  final String lastMessage;
  final String timeAgo;
  final int unreadCount;
  final String userInitials;
  final String productTitle;
  final double productPrice;
  final String deliveryType;
  final String trackingNumber;
  final String courierName;

  const ChatThreadModel({
    required this.id,
    required this.userName,
    required this.userRole,
    required this.productSubject,
    required this.lastMessage,
    required this.timeAgo,
    this.unreadCount = 0,
    required this.userInitials,
    this.productTitle = '',
    this.productPrice = 0.0,
    this.deliveryType = 'Courier',
    this.trackingNumber = '',
    this.courierName = '',
  });
}

class MessagesListScreen extends ConsumerStatefulWidget {
  const MessagesListScreen({super.key});

  @override
  ConsumerState<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends ConsumerState<MessagesListScreen> {
  int _selectedTab = 0; // 0 = Buyer, 1 = Seller
  bool _isLoading = true;

  List<ChatThreadModel> _buyerThreads = [];
  List<ChatThreadModel> _sellerThreads = [];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final currentUserId = ref.read(authProvider).user?.id;
      final res = await apiClient.get('/chat/rooms');

      if (res.data != null && res.data['success'] == true && res.data['data'] != null) {
        final List roomsJson = res.data['data'] as List;
        final List<ChatThreadModel> buyers = [];
        final List<ChatThreadModel> sellers = [];

        for (final item in roomsJson) {
          final map = item as Map<String, dynamic>;
          final id = map['id']?.toString() ?? '';
          final buyerId = map['buyerId']?.toString();
          final sellerId = map['sellerId']?.toString();
          final otherName = map['otherUserName']?.toString() ?? 'User';
          final otherRole = map['otherUserRole']?.toString() ?? 'Buyer';
          final listingTitle = map['listingTitle']?.toString() ?? 'Listing';
          final listingPrice = (map['listingPrice'] is num) ? (map['listingPrice'] as num).toDouble() : 0.0;
          final lastMsg = map['lastMessagePreview']?.toString() ?? 'Tap to view conversation';
          final unread = (map['unreadCount'] is int) ? map['unreadCount'] as int : 0;
          final initials = otherName.isNotEmpty
              ? otherName.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
              : 'U';

          final thread = ChatThreadModel(
            id: id,
            userName: otherName,
            userRole: otherRole,
            productSubject: 're: $listingTitle',
            lastMessage: lastMsg,
            timeAgo: 'Recent',
            unreadCount: unread,
            userInitials: initials,
            productTitle: listingTitle,
            productPrice: listingPrice,
            deliveryType: 'Courier',
          );

          if (currentUserId != null && currentUserId == buyerId) {
            buyers.add(thread);
          } else if (currentUserId != null && currentUserId == sellerId) {
            sellers.add(thread);
          } else {
            if (otherRole.toLowerCase() == 'seller') {
              buyers.add(thread);
            } else {
              sellers.add(thread);
            }
          }
        }

        if (mounted) {
          setState(() {
            _buyerThreads = buyers;
            _sellerThreads = sellers;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _selectedTab == 0 ? _buyerThreads : _sellerThreads;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppTheme.border.withValues(alpha: 0.7),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 14),

            // ── Tab Bar (Buyer vs Seller) ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Buyer',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13.5,
                                fontWeight: _selectedTab == 0 ? FontWeight.w700 : FontWeight.w500,
                                color: _selectedTab == 0 ? const Color(0xFF004E54) : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Seller',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13.5,
                                fontWeight: _selectedTab == 1 ? FontWeight.w700 : FontWeight.w500,
                                color: _selectedTab == 1 ? const Color(0xFF004E54) : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Messages List ──────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF004E54)),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchRooms,
                      color: const Color(0xFF004E54),
                      child: currentList.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded,
                                          size: 52,
                                          color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                                      const SizedBox(height: 12),
                                      Text(
                                        _selectedTab == 0
                                            ? 'No buyer conversations'
                                            : 'No seller conversations',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedTab == 0
                                            ? 'Offers you make will appear here.'
                                            : 'Offers you receive will appear here.',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: currentList.length,
                              separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  indent: 68,
                  color: AppTheme.border.withValues(alpha: 0.6),
                ),
                itemBuilder: (ctx, idx) {
                  final thread = currentList[idx];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            thread: thread,
                            isSellerView: _selectedTab == 1,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE5E7EB),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: Color(0xFF004E54),
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Name & Last Message
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      thread.userName,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      thread.timeAgo,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  thread.productSubject,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF004E54),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        thread.lastMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: thread.unreadCount > 0
                                              ? AppTheme.textPrimary
                                              : AppTheme.textSecondary,
                                          fontWeight: thread.unreadCount > 0
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    if (thread.unreadCount > 0)
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF005459),
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                        child: Center(
                                          child: Text(
                                            thread.unreadCount.toString(),
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              height: 1.0,
                                            ),
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
                    ),
                  );
                },
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
