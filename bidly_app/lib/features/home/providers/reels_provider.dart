import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../explore/models/listing_model.dart';

class ReelsState {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;
  final List<ListingModel> reelListings;
  final int activeTab; // 0 = Feed (Video Reels), 1 = Posts (Discussions)
  // Persisted like state across widget rebuilds
  final Map<String, bool> likedIds;
  final Map<String, int> likesCounts;

  const ReelsState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.errorMessage,
    this.reelListings = const [],
    this.activeTab = 0,
    this.likedIds = const {},
    this.likesCounts = const {},
  });

  ReelsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
    List<ListingModel>? reelListings,
    int? activeTab,
    Map<String, bool>? likedIds,
    Map<String, int>? likesCounts,
  }) {
    return ReelsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage,
      reelListings: reelListings ?? this.reelListings,
      activeTab: activeTab ?? this.activeTab,
      likedIds: likedIds ?? this.likedIds,
      likesCounts: likesCounts ?? this.likesCounts,
    );
  }

  bool isLiked(String listingId, [bool fallback = false]) =>
      likedIds[listingId] ?? fallback;
  int likesCount(String listingId, int serverCount) =>
      likesCounts[listingId] ?? serverCount;
}

class ReelsNotifier extends StateNotifier<ReelsState> {
  final ApiClient _apiClient;
  static const int _pageSize = 10;
  final Set<String> _inFlightLikes = {};
  static List<ListingModel> _cachedReels = [];
  static Map<String, bool> _cachedLikedIds = {};
  static Map<String, int> _cachedLikesCounts = {};

  ReelsNotifier(this._apiClient)
      : super(ReelsState(
          reelListings: _cachedReels,
          likedIds: _cachedLikedIds,
          likesCounts: _cachedLikesCounts,
          isLoading: _cachedReels.isEmpty,
        )) {
    fetchReels();
  }

  void setActiveTab(int index) {
    state = state.copyWith(activeTab: index);
  }

  /// Toggle or ensure like state. Optimistic update with in-flight deduplication and authoritative server confirmation.
  Future<void> toggleLike(
    String listingId,
    int serverLikesCount, {
    bool? targetLiked,
    bool initialLiked = false,
  }) async {
    final currentlyLiked = state.isLiked(listingId, initialLiked);
    final currentCount = state.likesCount(listingId, serverLikesCount);

    // If explicit target state is requested and already achieved, return immediately
    if (targetLiked != null && targetLiked == currentlyLiked) {
      return;
    }

    final newLiked = targetLiked ?? !currentlyLiked;
    final newCount = newLiked
        ? currentCount + 1
        : (currentCount > 0 ? currentCount - 1 : 0);

    // In-flight deduplication guard
    if (_inFlightLikes.contains(listingId)) {
      return;
    }
    _inFlightLikes.add(listingId);

    debugPrint('[LIKE] id=$listingId optimistic=$newLiked count=$newCount');

    // Optimistic update — instant UI response
    final newLikedIds = Map<String, bool>.from(state.likedIds)
      ..[listingId] = newLiked;
    final newLikesCounts = Map<String, int>.from(state.likesCounts)
      ..[listingId] = newCount;

    state = state.copyWith(likedIds: newLikedIds, likesCounts: newLikesCounts);

    try {
      final actionParam = targetLiked != null ? (targetLiked ? 'like' : 'unlike') : null;
      final url = actionParam != null
          ? '/listings/$listingId/like?action=$actionParam'
          : '/listings/$listingId/like';
      final response = await _apiClient.dio.post(url);

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          final serverLiked = data['isLikedByMe'] as bool? ?? data['likedByMe'] as bool? ?? newLiked;
          final serverCount = (data['likesCount'] as num?)?.toInt() ?? newCount;
          debugPrint('[LIKE] id=$listingId server=$serverLiked count=$serverCount');
          final confirmedLikedIds = Map<String, bool>.from(state.likedIds)..[listingId] = serverLiked;
          final confirmedCounts = Map<String, int>.from(state.likesCounts)..[listingId] = serverCount;
          state = state.copyWith(likedIds: confirmedLikedIds, likesCounts: confirmedCounts);
        }
      }
    } catch (e) {
      debugPrint('[LIKE] id=$listingId rollback=true error=$e');
      final revertLikedIds = Map<String, bool>.from(state.likedIds)
        ..[listingId] = currentlyLiked;
      final revertCounts = Map<String, int>.from(state.likesCounts)
        ..[listingId] = currentCount;
      state = state.copyWith(
          likedIds: revertLikedIds, likesCounts: revertCounts);
    } finally {
      _inFlightLikes.remove(listingId);
    }
  }

  Future<void> fetchReels({bool isRefresh = false}) async {
    if (state.isLoading && !isRefresh) return;
    if (!isRefresh && state.reelListings.isNotEmpty) return;

    if (state.reelListings.isEmpty || isRefresh) {
      state = state.copyWith(
        isLoading: state.reelListings.isEmpty,
        errorMessage: null,
        currentPage: 0,
        hasMore: true,
      );
    }

    try {
      final response = await _apiClient.dio.get('/listings/reels?page=0&size=$_pageSize');
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List;
        final videoReels = list
            .map((json) =>
                ListingModel.fromJson(json as Map<String, dynamic>))
            .where((item) =>
                item.reelUrl != null && item.reelUrl!.trim().isNotEmpty)
            .toList();

        final updatedLikedIds = Map<String, bool>.from(state.likedIds);
        final updatedCounts = Map<String, int>.from(state.likesCounts);
        for (final r in videoReels) {
          // Merge server state while preserving in-flight operations
          if (!_inFlightLikes.contains(r.id)) {
            updatedLikedIds[r.id] = r.isLikedByMe;
            updatedCounts[r.id] = r.likesCount;
          }
        }

        _cachedReels = videoReels;
        _cachedLikedIds = updatedLikedIds;
        _cachedLikesCounts = updatedCounts;

        state = state.copyWith(
          isLoading: false,
          reelListings: videoReels,
          currentPage: 0,
          hasMore: videoReels.length >= _pageSize,
          likedIds: updatedLikedIds,
          likesCounts: updatedCounts,
        );
      } else {
        state = state.copyWith(
            isLoading: false, errorMessage: 'Failed to load feed');
      }
    } catch (_) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to connect to feed server');
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _apiClient.dio.get('/listings/reels?page=$nextPage&size=$_pageSize');
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List;
        final newReels = list
            .map((json) =>
                ListingModel.fromJson(json as Map<String, dynamic>))
            .where((item) =>
                item.reelUrl != null && item.reelUrl!.trim().isNotEmpty)
            .toList();

        final existingIds = state.reelListings.map((r) => r.id).toSet();
        final uniqueNew = newReels.where((r) => !existingIds.contains(r.id)).toList();

        final updatedLikedIds = Map<String, bool>.from(state.likedIds);
        final updatedCounts = Map<String, int>.from(state.likesCounts);
        for (final r in uniqueNew) {
          if (!_inFlightLikes.contains(r.id)) {
            updatedLikedIds[r.id] = r.isLikedByMe;
            updatedCounts[r.id] = r.likesCount;
          }
        }

        state = state.copyWith(
          isLoadingMore: false,
          currentPage: nextPage,
          hasMore: newReels.length >= _pageSize,
          reelListings: [...state.reelListings, ...uniqueNew],
          likedIds: updatedLikedIds,
          likesCounts: updatedCounts,
        );
      } else {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      }
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final reelsProvider =
    StateNotifierProvider<ReelsNotifier, ReelsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReelsNotifier(apiClient);
});
