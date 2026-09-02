import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class MyListingItemModel {
  final String id;
  final String title;
  final double price;
  final String status; // ACTIVE, SHIPPING, COMPLETED, CANCELLED
  final String sellingMethod; // AUCTION, DIRECT_SALE
  final String? timeLeft;
  final int bidsCount;
  final String? subtext; // e.g. "In Transit" or "12 bids"
  final String? imageUrl;
  final String locality;

  const MyListingItemModel({
    required this.id,
    required this.title,
    required this.price,
    required this.status,
    required this.sellingMethod,
    this.timeLeft,
    this.bidsCount = 0,
    this.subtext,
    this.imageUrl,
    this.locality = 'Chennai',
  });

  factory MyListingItemModel.fromJson(Map<String, dynamic> json) {
    return MyListingItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Listing',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : (double.tryParse(json['price']?.toString() ?? '0') ?? 0.0),
      status: json['status']?.toString() ?? 'ACTIVE',
      sellingMethod: json['sellingMethod']?.toString() ?? 'AUCTION',
      timeLeft: json['timeLeft']?.toString(),
      bidsCount: (json['bidsCount'] is num) ? (json['bidsCount'] as num).toInt() : 0,
      subtext: json['subtext']?.toString(),
      imageUrl: json['primaryImageUrl']?.toString(),
      locality: json['locality']?.toString() ?? 'Chennai',
    );
  }
}

class MyListingsState {
  final List<MyListingItemModel> auctionListings;
  final List<MyListingItemModel> directListings;
  final bool isLoading;
  final String selectedTab; // 'AUCTION' | 'DIRECT'
  final String selectedFilter; // 'ALL', 'ACTIVE', 'SHIPPING', 'COMPLETED', 'CANCELLED'

  const MyListingsState({
    this.auctionListings = const [],
    this.directListings = const [],
    this.isLoading = false,
    this.selectedTab = 'AUCTION',
    this.selectedFilter = 'ALL',
  });

  MyListingsState copyWith({
    List<MyListingItemModel>? auctionListings,
    List<MyListingItemModel>? directListings,
    bool? isLoading,
    String? selectedTab,
    String? selectedFilter,
  }) {
    return MyListingsState(
      auctionListings: auctionListings ?? this.auctionListings,
      directListings: directListings ?? this.directListings,
      isLoading: isLoading ?? this.isLoading,
      selectedTab: selectedTab ?? this.selectedTab,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

class MyListingsNotifier extends StateNotifier<MyListingsState> {
  final ApiClient _apiClient;

  MyListingsNotifier(this._apiClient) : super(const MyListingsState()) {
    fetchMyListings();
  }

  Future<void> fetchMyListings() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _apiClient.get('/listings/my');
      if (res.data != null && res.data['success'] == true && res.data['data'] != null) {
        final list = (res.data['data'] as List)
            .map((item) => MyListingItemModel.fromJson(item as Map<String, dynamic>))
            .toList();

        final auctions = list.where((l) => l.sellingMethod == 'AUCTION').toList();
        final directs = list.where((l) => l.sellingMethod != 'AUCTION').toList();

        state = state.copyWith(
          auctionListings: auctions,
          directListings: directs,
          isLoading: false,
        );
        return;
      }
    } catch (_) {}

    state = state.copyWith(
      auctionListings: [],
      directListings: [],
      isLoading: false,
    );
  }

  void setTab(String tab) {
    state = state.copyWith(selectedTab: tab);
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }
}

final myListingsProvider =
    StateNotifierProvider<MyListingsNotifier, MyListingsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MyListingsNotifier(apiClient);
});
