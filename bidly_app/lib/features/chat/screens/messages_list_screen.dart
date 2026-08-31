import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
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
    this.productTitle = 'iPhone 13 Pro · 256GB',
    this.productPrice = 43500,
    this.deliveryType = 'Courier',
    this.trackingNumber = '2345678',
    this.courierName = 'Ekart Logistics',
  });
}

class MessagesListScreen extends ConsumerStatefulWidget {
  const MessagesListScreen({super.key});

  @override
  ConsumerState<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends ConsumerState<MessagesListScreen> {
  int _selectedTab = 0; // 0 = Buyer, 1 = Seller

  final List<ChatThreadModel> _buyerThreads = [
    const ChatThreadModel(
      id: 'thread-buyer-1',
      userName: 'Ravi Kumar',
      userRole: 'Seller',
      productSubject: 're: MacBook Air M2',
      lastMessage: 'Is the MacBook still available?',
      timeAgo: '2m',
      unreadCount: 2,
      userInitials: 'RK',
      productTitle: 'MacBook Air M2 · 512GB',
      productPrice: 75000,
    ),
    const ChatThreadModel(
      id: 'thread-buyer-2',
      userName: 'Meena Stores',
      userRole: 'Seller',
      productSubject: 're: Sony WH-1000XM5',
      lastMessage: 'Your order has been shipped!',
      timeAgo: '1h',
      unreadCount: 0,
      userInitials: 'MS',
      productTitle: 'Sony WH-1000XM5 Headphones',
      productPrice: 21000,
    ),
    const ChatThreadModel(
      id: 'thread-buyer-3',
      userName: 'Arun Textiles',
      userRole: 'Seller',
      productSubject: 're: Study Chair',
      lastMessage: 'Deal confirmed. Meetup tomorrow 5PM',
      timeAgo: '3h',
      unreadCount: 1,
      userInitials: 'AT',
      productTitle: 'Ergonomic Study Chair',
      productPrice: 4200,
    ),
  ];

  final List<ChatThreadModel> _sellerThreads = [
    const ChatThreadModel(
      id: 'thread-seller-1',
      userName: 'Priya Menon',
      userRole: 'Buyer',
      productSubject: 're: Sony Headphones',
      lastMessage: 'Can you do ₹2,800?',
      timeAgo: '5m',
      unreadCount: 3,
      userInitials: 'PM',
      productTitle: 'Sony Extra Bass Headphones',
      productPrice: 2800,
    ),
    const ChatThreadModel(
      id: 'thread-seller-2',
      userName: 'Kiran Reddy',
      userRole: 'Buyer',
      productSubject: 're: Gaming Laptop',
      lastMessage: "I'll take it. What's the meetup spot?",
      timeAgo: '30m',
      unreadCount: 0,
      userInitials: 'KR',
      productTitle: 'ASUS ROG Gaming Laptop',
      productPrice: 65000,
    ),
    const ChatThreadModel(
      id: 'thread-seller-3',
      userName: 'Lokesh',
      userRole: 'Buyer',
      productSubject: 're: iPhone 13 Pro',
      lastMessage: 'You have shared tracking details.',
      timeAgo: '2h',
      unreadCount: 0,
      userInitials: 'LK',
      productTitle: 'iPhone 13 Pro · 256GB',
      productPrice: 43500,
    ),
  ];

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
              child: ListView.separated(
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
          ],
        ),
      ),
    );
  }
}
