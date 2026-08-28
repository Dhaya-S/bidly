import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/listing_model.dart';
import '../models/top_seller_model.dart';

class ExploreState {
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? errorMessage;
  final String selectedCategory;
  final String selectedSellingMethod; // ALL, DIRECT_BUY, AUCTION
  final String searchQuery;
  final int selectedRadiusKm;
  final List<ListingModel> dealsNearYou;
  final List<TopSellerModel> topSellers;
  final List<ListingModel> recentlyViewed;
  final List<ListingModel> marketplaceListings;
  final int currentPage;
  final bool hasMore;
  final DateTime? lastUpdated;

  const ExploreState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.selectedCategory = 'All',
    this.selectedSellingMethod = 'ALL',
    this.searchQuery = '',
    this.selectedRadiusKm = 10,
    this.dealsNearYou = const [],
    this.topSellers = const [],
    this.recentlyViewed = const [],
    this.marketplaceListings = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.lastUpdated,
  });

  ExploreState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? errorMessage,
    String? selectedCategory,
    String? selectedSellingMethod,
    String? searchQuery,
    int? selectedRadiusKm,
    List<ListingModel>? dealsNearYou,
    List<TopSellerModel>? topSellers,
    List<ListingModel>? recentlyViewed,
    List<ListingModel>? marketplaceListings,
    int? currentPage,
    bool? hasMore,
    DateTime? lastUpdated,
  }) {
    return ExploreState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedSellingMethod: selectedSellingMethod ?? this.selectedSellingMethod,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRadiusKm: selectedRadiusKm ?? this.selectedRadiusKm,
      dealsNearYou: dealsNearYou ?? this.dealsNearYou,
      topSellers: topSellers ?? this.topSellers,
      recentlyViewed: recentlyViewed ?? this.recentlyViewed,
      marketplaceListings: marketplaceListings ?? this.marketplaceListings,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class ExploreNotifier extends StateNotifier<ExploreState> {
  final ApiClient _apiClient;
  final Ref _ref;
  Timer? _debounceTimer;

  ExploreNotifier(this._apiClient, this._ref) : super(const ExploreState()) {
    final user = _ref.read(authProvider).user;
    if (user != null && user.searchRadiusKm > 0) {
      state = state.copyWith(selectedRadiusKm: user.searchRadiusKm);
    }
    fetchExploreData();
  }

  String _buildLocationParams() {
    final user = _ref.read(authProvider).user;
    final latParam = user?.latitude != null ? '&lat=${user!.latitude}' : '';
    final lngParam = user?.longitude != null ? '&lng=${user!.longitude}' : '';
    final radiusParam = '&radiusKm=${state.selectedRadiusKm}';
    return '$latParam$lngParam$radiusParam';
  }

  Future<void> fetchExploreData({bool isRefresh = false}) async {
    if (state.isLoading && !isRefresh) return;

    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, errorMessage: null, currentPage: 0, hasMore: true);
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null, currentPage: 0, hasMore: true);
    }

    final locParams = _buildLocationParams();
    final catParam = state.selectedCategory == 'All' ? '' : '&category=${state.selectedCategory}';
    final methodParam = state.selectedSellingMethod == 'ALL' ? '' : '&method=${state.selectedSellingMethod}';
    final qParam = state.searchQuery.isEmpty ? '' : '&q=${state.searchQuery}';

    // 1. Fetch Primary Marketplace Listings (10 items per page)
    _apiClient.dio.get('/listings/search?page=0&size=10$catParam$methodParam$qParam$locParams').then((res) {
      if (res.data != null && res.data['success'] == true) {
        final list = res.data['data'] as List;
        final listings = list.map((j) => ListingModel.fromJson(j as Map<String, dynamic>)).toList();
        state = state.copyWith(
          marketplaceListings: listings,
          isLoading: false,
          isRefreshing: false,
          currentPage: 0,
          hasMore: listings.length >= 10,
          lastUpdated: DateTime.now(),
        );
      } else {
        state = state.copyWith(isLoading: false, isRefreshing: false);
      }
    }).catchError((_) {
      state = state.copyWith(isLoading: false, isRefreshing: false);
    });

    // 2. Fetch Deals Near You independently
    _apiClient.dio.get('/listings/deals-near-you?$locParams').then((res) {
      if (res.data != null && res.data['success'] == true) {
        final list = res.data['data'] as List;
        final deals = list.map((j) => ListingModel.fromJson(j as Map<String, dynamic>)).toList();
        state = state.copyWith(dealsNearYou: deals);
      }
    }).catchError((_) {});

    // 3. Fetch Top Sellers independently
    _apiClient.dio.get('/listings/top-sellers').then((res) {
      if (res.data != null && res.data['success'] == true) {
        final list = res.data['data'] as List;
        final sellers = list.map((j) => TopSellerModel.fromJson(j as Map<String, dynamic>)).toList();
        state = state.copyWith(topSellers: sellers);
      }
    }).catchError((_) {});

    // 4. Fetch Recently Viewed independently
    _apiClient.dio.get('/listings/recently-viewed').then((res) {
      if (res.data != null && res.data['success'] == true) {
        final list = res.data['data'] as List;
        final recent = list.map((j) => ListingModel.fromJson(j as Map<String, dynamic>)).toList();
        state = state.copyWith(recentlyViewed: recent);
      }
    }).catchError((_) {});
  }

  Future<void> fetchNextPage() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;
    final locParams = _buildLocationParams();
    final catParam = state.selectedCategory == 'All' ? '' : '&category=${state.selectedCategory}';
    final methodParam = state.selectedSellingMethod == 'ALL' ? '' : '&method=${state.selectedSellingMethod}';
    final qParam = state.searchQuery.isEmpty ? '' : '&q=${state.searchQuery}';

    try {
      final res = await _apiClient.dio.get('/listings/search?page=$nextPage&size=10$catParam$methodParam$qParam$locParams');
      if (res.data != null && res.data['success'] == true) {
        final list = res.data['data'] as List;
        final newItems = list.map((j) => ListingModel.fromJson(j as Map<String, dynamic>)).toList();
        state = state.copyWith(
          marketplaceListings: [...state.marketplaceListings, ...newItems],
          currentPage: nextPage,
          hasMore: newItems.length >= 10,
          isLoadingMore: false,
        );
      } else {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      }
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setRadiusKm(int radiusKm) {
    if (state.selectedRadiusKm == radiusKm) return;
    state = state.copyWith(selectedRadiusKm: radiusKm);
    fetchExploreData(isRefresh: true);
  }

  void selectCategory(String category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category);
    fetchExploreData(isRefresh: true);
  }

  void selectSellingMethod(String method) {
    if (state.selectedSellingMethod == method) return;
    state = state.copyWith(selectedSellingMethod: method);
    fetchExploreData(isRefresh: true);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      fetchExploreData(isRefresh: true);
    });
  }

  Future<void> toggleLike(String listingId) async {
    final updatedListings = state.marketplaceListings.map((l) {
      if (l.id == listingId) {
        final newWishlisted = !l.isWishlisted;
        return l.copyWith(isWishlisted: newWishlisted);
      }
      return l;
    }).toList();

    final updatedDeals = state.dealsNearYou.map((l) {
      if (l.id == listingId) {
        final newWishlisted = !l.isWishlisted;
        return l.copyWith(isWishlisted: newWishlisted);
      }
      return l;
    }).toList();

    state = state.copyWith(
      marketplaceListings: updatedListings,
      dealsNearYou: updatedDeals,
    );

    try {
      await _apiClient.post('/listings/$listingId/like');
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final exploreProvider = StateNotifierProvider<ExploreNotifier, ExploreState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExploreNotifier(apiClient, ref);
});
