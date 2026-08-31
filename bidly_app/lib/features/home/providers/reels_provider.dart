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
  final Set<int> _requestedPages = {};
  final Set<int> _completedPages = {};
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

    // In-flight deduplication guard
    if (_inFlightLikes.contains(listingId)) {
      debugPrint('[LIKE_REQUEST] id=$listingId duplicate=in_flight_ignored');
      return;
    }
    _inFlightLikes.add(listingId);

    final newLiked = targetLiked ?? !currentlyLiked;
    final newCount = newLiked
        ? currentCount + 1
        : (currentCount > 0 ? currentCount - 1 : 0);

    debugPrint('[LIKE_REEL] listing=$listingId action=${targetLiked != null ? (targetLiked ? "like" : "unlike") : "toggle"} optimistic=$newLiked count=$newCount');

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
          final serverLiked = data['isLikedByMe'] as bool? ?? data['likedByMe'] as bool? ?? data['liked'] as bool? ?? newLiked;
          final serverCount = (data['likesCount'] as num?)?.toInt() ?? newCount;
          debugPrint('[LIKE_REEL] listing=$listingId server=$serverLiked count=$serverCount');
          final confirmedLikedIds = Map<String, bool>.from(state.likedIds)..[listingId] = serverLiked;
          final confirmedCounts = Map<String, int>.from(state.likesCounts)..[listingId] = serverCount;
          state = state.copyWith(likedIds: confirmedLikedIds, likesCounts: confirmedCounts);
        }
      }
    } catch (e) {
      debugPrint('[LIKE_REEL] listing=$listingId rollback=true error=$e');
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

    if (state.reelListings.isEmpty || isRefresh) {
      state = state.copyWith(
        isLoading: state.reelListings.isEmpty,
        errorMessage: null,
        currentPage: 0,
        hasMore: true,
      );
    }

    _requestedPages.clear();
    _completedPages.clear();
    _requestedPages.add(0);

    debugPrint('[REELS_PAGINATION] INITIAL page=0 size=$_pageSize');

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

        _completedPages.add(0);

        final updatedLikedIds = Map<String, bool>.from(state.likedIds);
        final updatedCounts = Map<String, int>.from(state.likesCounts);
        for (final r in videoReels) {
          if (!_inFlightLikes.contains(r.id)) {
            updatedLikedIds[r.id] = r.isLikedByMe;
            updatedCounts[r.id] = r.likesCount;
          }
        }

        _cachedReels = videoReels;
        _cachedLikedIds = updatedLikedIds;
        _cachedLikesCounts = updatedCounts;

        final hasMore = videoReels.length >= _pageSize;
        state = state.copyWith(
          isLoading: false,
          reelListings: videoReels,
          currentPage: 0,
          hasMore: hasMore,
          likedIds: updatedLikedIds,
          likesCounts: updatedCounts,
        );

        debugPrint('[REELS_PAGINATION] SUCCESS page=0 received=${videoReels.length} totalLoaded=${videoReels.length} hasMore=$hasMore');
        if (!hasMore) {
          debugPrint('[REELS_PAGINATION] END_OF_FEED totalLoaded=${videoReels.length}');
        }
      } else {
        _requestedPages.remove(0);
        state = state.copyWith(
            isLoading: false, errorMessage: 'Failed to load feed');
      }
    } catch (e) {
      _requestedPages.remove(0);
      debugPrint('[REELS_PAGINATION] ERROR page=0 error=$e');
      state = state.copyWith(
          isLoading: false,
          errorMessage: state.reelListings.isEmpty ? 'Unable to connect to feed server' : null);
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.currentPage + 1;

    if (_requestedPages.contains(nextPage)) {
      debugPrint('[REELS_PAGINATION] SKIP page=$nextPage reason=in_flight');
      return;
    }
    if (_completedPages.contains(nextPage)) {
      debugPrint('[REELS_PAGINATION] SKIP page=$nextPage reason=already_loaded');
      return;
    }

    _requestedPages.add(nextPage);
    state = state.copyWith(isLoadingMore: true);
    debugPrint('[REELS_PAGINATION] REQUEST page=$nextPage');

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

        _completedPages.add(nextPage);

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

        final accumulated = [...state.reelListings, ...uniqueNew];
        final hasMore = newReels.length >= _pageSize;

        state = state.copyWith(
          isLoadingMore: false,
          currentPage: nextPage,
          hasMore: hasMore,
          reelListings: accumulated,
          likedIds: updatedLikedIds,
          likesCounts: updatedCounts,
        );

        debugPrint('[REELS_PAGINATION] SUCCESS page=$nextPage received=${newReels.length} totalLoaded=${accumulated.length} hasMore=$hasMore');
        if (!hasMore) {
          debugPrint('[REELS_PAGINATION] END_OF_FEED totalLoaded=${accumulated.length}');
        }
      } else {
        _requestedPages.remove(nextPage);
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      }
    } catch (e) {
      _requestedPages.remove(nextPage);
      debugPrint('[REELS_PAGINATION] ERROR page=$nextPage error=$e');
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final reelsProvider =
    StateNotifierProvider<ReelsNotifier, ReelsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReelsNotifier(apiClient);
});
