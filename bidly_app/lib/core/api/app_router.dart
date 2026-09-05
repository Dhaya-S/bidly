import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/setup/screens/identity_verification_screen.dart';
import '../../features/setup/screens/identity_processing_screen.dart';
import '../../features/setup/screens/location_setup_screen.dart';
import '../../features/setup/screens/category_interests_screen.dart';
import '../../features/home/screens/main_shell_screen.dart';
import '../../features/sell/screens/sell_item_screen.dart';
import '../../features/sell/screens/selling_scope_screen.dart';
import '../../features/sell/screens/sell_type_screen.dart';
import '../../features/sell/screens/sell_preview_screen.dart';
import '../../features/sell/screens/sell_success_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/personal_information_screen.dart';
import '../../features/profile/screens/add_money_screen.dart';
import '../../features/profile/screens/money_added_success_screen.dart';
import '../../features/profile/screens/orders_screen.dart';
import '../../features/profile/screens/product_history_screen.dart';
import '../../features/profile/screens/notifications_screen.dart';
import '../../features/profile/screens/privacy_security_screen.dart';
import '../../features/profile/screens/help_support_screen.dart';
import '../../features/profile/screens/my_listings_screen.dart';
import '../../features/profile/screens/wishlist_screen.dart';
import '../../features/profile/providers/wallet_provider.dart';
import '../../features/profile/providers/orders_provider.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/chat/screens/messages_list_screen.dart';
import '../../features/chat/screens/chat_detail_screen.dart';
import '../../features/community/screens/communities_screen.dart';
import '../../features/community/screens/explore_communities_screen.dart';
import '../../features/community/screens/create_community_screen.dart';
import '../../features/community/screens/community_success_screen.dart';
import '../../features/listing/screens/listing_detail_screen.dart';
import '../../features/chat/screens/offer_chat_screen.dart';
import '../../features/explore/models/listing_model.dart';
import '../../features/auction/screens/place_bid_screen.dart';
import '../../features/auction/screens/auction_tracker_screen.dart';
import '../../features/auction/screens/auction_won_screen.dart';
import '../../features/auction/screens/track_order_screen.dart';
import '../../features/auction/screens/delivery_confirmation_screen.dart';
import '../../features/auction/screens/review_rating_screen.dart';
import '../../features/subscription/screens/seller_subscription_screen.dart';
import '../../features/chat/screens/seller_otp_verification_screen.dart';
import '../../features/chat/screens/seller_otp_verified_screen.dart';
import '../../features/chat/screens/product_sold_success_screen.dart';
import '../../features/profile/screens/sale_summary_screen.dart';

/// Placeholder screen for routes not yet implemented
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 48, color: Color(0xFF004E54)),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('UI coming in next step',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ],
          ),
        ),
      );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.phoneEntry,
        name: 'phoneEntry',
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        name: 'otpVerify',
        builder: (_, __) => const OtpVerificationScreen(),
      ),
      // Post-signup setup routes
      GoRoute(
        path: AppRoutes.setupIdentity,
        name: 'setupIdentity',
        builder: (_, __) => const IdentityVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupProcessing,
        name: 'setupProcessing',
        builder: (_, __) => const IdentityProcessingScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupLocation,
        name: 'setupLocation',
        builder: (_, __) => const LocationSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupInterests,
        name: 'setupInterests',
        builder: (_, __) => const CategoryInterestsScreen(),
      ),
      // Main app
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (_, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final initialIndex = tabStr != null ? int.tryParse(tabStr) ?? 0 : 0;
          return MainShellScreen(
            key: ValueKey('main_shell_$initialIndex'),
            initialIndex: initialIndex,
          );
        },
      ),
      // Sell Flow Routes
      GoRoute(
        path: AppRoutes.sell,
        name: 'sell',
        builder: (_, __) => const SellItemScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellScope,
        name: 'sellScope',
        builder: (_, __) => const SellingScopeScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellType,
        name: 'sellType',
        builder: (_, __) => const SellTypeScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellPreview,
        name: 'sellPreview',
        builder: (_, __) => const SellPreviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellSuccess,
        name: 'sellSuccess',
        builder: (_, __) => const SellSuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (_, __) => const PlaceholderScreen('Search'),
      ),
      GoRoute(
        path: AppRoutes.createListing,
        name: 'createListing',
        builder: (_, __) => const SellItemScreen(),
      ),
      GoRoute(
        path: AppRoutes.listingDetail,
        name: 'listingDetail',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          ListingModel? listing;
          if (state.extra is ListingModel) {
            listing = state.extra as ListingModel;
          } else if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            listing = map['listing'] as ListingModel?;
          }
          return ListingDetailScreen(listingId: id, initialListing: listing);
        },
      ),
      GoRoute(
        path: AppRoutes.offerChat,
        name: 'offerChat',
        builder: (ctx, state) {
          final id = state.pathParameters['listingId'] ?? '';
          ListingModel? listing;
          String? buyerId = state.uri.queryParameters['buyerId'];
          String? offerId = state.uri.queryParameters['offerId'];
          String? orderId = state.uri.queryParameters['orderId'];
          String? buyerName = state.uri.queryParameters['buyerName'];
          String? roomId = state.uri.queryParameters['roomId'];
          String? productTitle;
          double? productPrice;
          String? listingImageUrl;
          String? sellerId;
          bool? isSellerView;

          if (state.extra is ListingModel) {
            listing = state.extra as ListingModel;
          } else if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            listing = map['listing'] as ListingModel?;
            buyerId ??= map['buyerId'] as String?;
            offerId ??= map['offerId'] as String?;
            orderId ??= map['orderId'] as String?;
            buyerName ??= map['buyerName'] as String?;
            roomId ??= map['roomId'] as String?;
            productTitle = map['productTitle'] as String?;
            productPrice = (map['productPrice'] is num) ? (map['productPrice'] as num).toDouble() : null;
            listingImageUrl = map['listingImageUrl'] as String?;
            sellerId = map['sellerId'] as String?;
            isSellerView = map['isSeller'] as bool? ?? map['isSellerView'] as bool?;
          }

          sellerId ??= state.uri.queryParameters['sellerId'] ?? listing?.sellerId;
          if (state.uri.queryParameters['isSeller'] != null) {
            isSellerView ??= state.uri.queryParameters['isSeller'] == 'true';
          }

          return OfferChatScreen(
            listingId: id,
            listing: listing,
            buyerId: buyerId,
            sellerId: sellerId,
            isSellerView: isSellerView,
            offerId: offerId,
            orderId: orderId,
            buyerName: buyerName,
            roomId: roomId,
            productTitle: productTitle,
            productPrice: productPrice,
            listingImageUrl: listingImageUrl,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.auctionBid,
        name: 'auctionBid',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          return PlaceBidScreen(listingId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.auctionTracker,
        name: 'auctionTracker',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          return AuctionTrackerScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/auction/tracker/:id',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          return AuctionTrackerScreen(listingId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.auctionWon,
        name: 'auctionWon',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          return AuctionWonScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/auctions/:id/won',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          return AuctionWonScreen(listingId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.orderTrack,
        name: 'orderTrack',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          return TrackOrderScreen(orderId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.orderTrackByListing,
        name: 'orderTrackByListing',
        builder: (ctx, state) {
          final listingId = state.pathParameters['listingId'] ?? '';
          return TrackOrderScreen(listingId: listingId);
        },
      ),
      GoRoute(
        path: AppRoutes.orderDeliveryConfirmation,
        name: 'orderDeliveryConfirmation',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          return DeliveryConfirmationScreen(orderId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.orderReview,
        name: 'orderReview',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          return ReviewRatingScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/orders/:id/verify-otp',
        name: 'verifyOrderOtp',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return SellerOtpVerificationScreen(
            orderId: id,
            buyerName: extra?['buyerName']?.toString(),
            meetupTime: extra?['meetupTime']?.toString(),
            meetupLocation: extra?['meetupLocation']?.toString(),
            productTitle: extra?['productTitle']?.toString(),
            productPrice: (extra?['productPrice'] is num) ? (extra!['productPrice'] as num).toDouble() : null,
            productImageUrl: extra?['productImageUrl']?.toString(),
          );
        },
      ),
      GoRoute(
        path: '/orders/:id/otp-verified',
        name: 'orderOtpVerified',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return SellerOtpVerifiedScreen(
            orderId: id,
            buyerName: extra?['buyerName']?.toString() ?? '',
            productTitle: extra?['productTitle']?.toString() ?? '',
            productPrice: (extra?['productPrice'] is num) ? (extra!['productPrice'] as num).toDouble() : 0.0,
            productImageUrl: extra?['productImageUrl']?.toString(),
          );
        },
      ),
      GoRoute(
        path: '/orders/:id/sold-success',
        name: 'productSoldSuccess',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return ProductSoldSuccessScreen(
            orderId: id,
            productTitle: extra?['productTitle']?.toString() ?? '',
            buyerName: extra?['buyerName']?.toString() ?? '',
            productPrice: (extra?['productPrice'] is num) ? (extra!['productPrice'] as num).toDouble() : 0.0,
            transactionId: extra?['transactionId']?.toString() ?? '',
            dateFormatted: extra?['dateFormatted']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: '/orders/:id/sale-summary',
        name: 'orderSaleSummary',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          return SaleSummaryScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/my-listings/sale-summary/:id',
        name: 'myListingsSaleSummary',
        builder: (ctx, state) {
          final id = state.pathParameters['id'] ?? '';
          return SaleSummaryScreen(orderId: id);
        },
      ),
      // Chat & Messages Flow
      GoRoute(
        path: AppRoutes.chatList,
        name: 'chatList',
        builder: (_, __) => const MessagesListScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatConversation,
        name: 'chatConversation',
        builder: (ctx, state) {
          final thread = state.extra as ChatThreadModel?;
          if (thread == null) {
            return const MessagesListScreen();
          }
          return ChatDetailScreen(thread: thread);
        },
      ),
      // Profile Tab & Sub-flows
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.personalInfo,
        name: 'personalInfo',
        builder: (_, __) => const PersonalInformationScreen(),
      ),
      GoRoute(
        path: AppRoutes.addMoney,
        name: 'addMoney',
        builder: (_, state) {
          final minTopUp = double.tryParse(state.uri.queryParameters['minTopUp'] ?? '');
          return AddMoneyScreen(minTopUp: minTopUp);
        },
      ),
      GoRoute(
        path: AppRoutes.moneyAddedSuccess,
        name: 'moneyAddedSuccess',
        builder: (ctx, state) {
          if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            final txn = map['transaction'] as WalletTransaction;
            final isFromBidding = map['isFromBidding'] as bool? ?? false;
            return MoneyAddedSuccessScreen(transaction: txn, isFromBidding: isFromBidding);
          }
          final txn = state.extra as WalletTransaction?;
          if (txn == null) {
            return const AddMoneyScreen();
          }
          return MoneyAddedSuccessScreen(transaction: txn);
        },
      ),
      GoRoute(
        path: AppRoutes.orders,
        name: 'orders',
        builder: (_, __) => const OrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.productHistory,
        name: 'productHistory',
        builder: (ctx, state) {
          final order = state.extra as OrderModel?;
          if (order == null) {
            return const OrdersScreen();
          }
          return ProductHistoryScreen(order: order);
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacySecurity,
        name: 'privacySecurity',
        builder: (_, __) => const PrivacySecurityScreen(),
      ),
      GoRoute(
        path: AppRoutes.helpSupport,
        name: 'helpSupport',
        builder: (_, __) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.myListings,
        name: 'myListings',
        builder: (_, __) => const MyListingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.wishlist,
        name: 'wishlist',
        builder: (_, __) => const WishlistScreen(),
      ),
      GoRoute(
        path: AppRoutes.savedListings,
        name: 'savedListings',
        builder: (_, __) => const WishlistScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellerSubscription,
        name: 'sellerSubscription',
        builder: (_, __) => const SellerSubscriptionScreen(),
      ),
      // Community
      GoRoute(
        path: AppRoutes.community,
        name: 'community',
        builder: (_, __) => const CommunitiesScreen(),
      ),
      GoRoute(
        path: AppRoutes.exploreCommunities,
        name: 'exploreCommunities',
        builder: (_, __) => const ExploreCommunitiesScreen(),
      ),
      GoRoute(
        path: AppRoutes.createCommunity,
        name: 'createCommunity',
        builder: (_, __) => const CreateCommunityScreen(),
      ),
      GoRoute(
        path: AppRoutes.communitySuccess,
        name: 'communitySuccess',
        builder: (_, state) {
          final name = state.uri.queryParameters['name'] ?? 'Community';
          return CommunitySuccessScreen(communityName: name);
        },
      ),
    ],
  );
});
