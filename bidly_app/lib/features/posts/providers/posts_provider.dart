import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/post_model.dart';

class PostsState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final List<PostModel> posts;
  final int activeTab; // 0 = Feed, 1 = Posts
  final int currentPage;
  final bool hasMore;
  final Map<String, bool> likedPostIds;
  final Map<String, int> postLikesCounts;

  const PostsState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.posts = const [],
    this.activeTab = 1,
    this.currentPage = 0,
    this.hasMore = true,
    this.likedPostIds = const {},
    this.postLikesCounts = const {},
  });

  PostsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    List<PostModel>? posts,
    int? activeTab,
    int? currentPage,
    bool? hasMore,
    Map<String, bool>? likedPostIds,
    Map<String, int>? postLikesCounts,
  }) {
    return PostsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      posts: posts ?? this.posts,
      activeTab: activeTab ?? this.activeTab,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      likedPostIds: likedPostIds ?? this.likedPostIds,
      postLikesCounts: postLikesCounts ?? this.postLikesCounts,
    );
  }

  bool isLiked(String postId, [bool fallback = false]) =>
      likedPostIds[postId] ?? fallback;

  int likesCount(String postId, int serverCount) =>
      postLikesCounts[postId] ?? serverCount;
}

class PostsNotifier extends StateNotifier<PostsState> {
  final ApiClient _apiClient;
  static const int _pageSize = 10;
  final Set<String> _inFlightLikes = {};

  PostsNotifier(this._apiClient) : super(const PostsState()) {
    fetchFeed();
  }

  void setActiveTab(int index) {
    state = state.copyWith(activeTab: index);
  }

  /// Realtime instant insertion of a newly created post at index 0.
  void insertNewPost(PostModel newPost) {
    final filtered = state.posts.where((p) => p.id != newPost.id).toList();
    final updated = [newPost, ...filtered];

    final newLiked = Map<String, bool>.from(state.likedPostIds)..[newPost.id] = newPost.isLikedByMe;
    final newCounts = Map<String, int>.from(state.postLikesCounts)..[newPost.id] = newPost.likesCount;

    state = state.copyWith(
      posts: updated,
      likedPostIds: newLiked,
      postLikesCounts: newCounts,
      isLoading: false,
    );
    debugPrint('[POSTS_REALTIME] Inserted newly created post: ${newPost.id} at index 0');
  }

  Future<void> fetchFeed({bool isRefresh = false}) async {
    if (state.isLoading && !isRefresh) return;
    if (!isRefresh && state.posts.isNotEmpty) return;

    state = state.copyWith(
      isLoading: state.posts.isEmpty,
      errorMessage: null,
      currentPage: 0,
      hasMore: true,
    );

    try {
      final response = await _apiClient.dio.get('/posts?page=0&size=$_pageSize');
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List;
        final fetchedPosts = list
            .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
            .toList();

        final newLiked = Map<String, bool>.from(state.likedPostIds);
        final newCounts = Map<String, int>.from(state.postLikesCounts);
        for (final p in fetchedPosts) {
          if (!newLiked.containsKey(p.id)) {
            newLiked[p.id] = p.isLikedByMe;
          }
          if (!newCounts.containsKey(p.id)) {
            newCounts[p.id] = p.likesCount;
          }
        }

        final backendIds = fetchedPosts.map((p) => p.id).toSet();
        // Preserve any newly inserted local posts not yet returned by backend
        final localPending = state.posts.where((p) => !backendIds.contains(p.id)).toList();
        final finalPosts = [...localPending, ...fetchedPosts];

        state = state.copyWith(
          isLoading: false,
          posts: finalPosts,
          currentPage: 0,
          hasMore: fetchedPosts.length >= _pageSize,
          likedPostIds: newLiked,
          postLikesCounts: newCounts,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load posts',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to connect to feed server',
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _apiClient.dio.get('/posts?page=$nextPage&size=$_pageSize');
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List;
        final newPosts = list
            .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
            .toList();

        final existingIds = state.posts.map((p) => p.id).toSet();
        final uniqueNew = newPosts.where((p) => !existingIds.contains(p.id)).toList();

        final newLiked = Map<String, bool>.from(state.likedPostIds);
        final newCounts = Map<String, int>.from(state.postLikesCounts);
        for (final p in uniqueNew) {
          newLiked[p.id] = p.isLikedByMe;
          newCounts[p.id] = p.likesCount;
        }

        state = state.copyWith(
          isLoadingMore: false,
          currentPage: nextPage,
          hasMore: newPosts.length >= _pageSize,
          posts: [...state.posts, ...uniqueNew],
          likedPostIds: newLiked,
          postLikesCounts: newCounts,
        );
      } else {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      }
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Toggle or ensure like on a post with idempotency, in-flight deduplication, and optimistic update.
  Future<void> toggleLike(
    String postId,
    int serverLikesCount, {
    bool? targetLiked,
    bool initialLiked = false,
  }) async {
    final currentlyLiked = state.isLiked(postId, initialLiked);
    final currentCount = state.likesCount(postId, serverLikesCount);

    // If target state is specified and already satisfied, do nothing
    if (targetLiked != null && targetLiked == currentlyLiked) {
      return;
    }

    // In-flight deduplication guard
    if (_inFlightLikes.contains(postId)) {
      debugPrint('[LIKE_REQUEST] id=$postId duplicate=in_flight_ignored');
      return;
    }
    _inFlightLikes.add(postId);

    final newLiked = targetLiked ?? !currentlyLiked;
    final newCount = newLiked
        ? currentCount + 1
        : (currentCount > 0 ? currentCount - 1 : 0);

    debugPrint('[LIKE_POST] post=$postId action=${targetLiked != null ? (targetLiked ? "like" : "unlike") : "toggle"} optimistic=$newLiked count=$newCount');

    // Optimistic UI update — targeted map update without rebuilding entire post list
    final optimisticLiked = Map<String, bool>.from(state.likedPostIds)..[postId] = newLiked;
    final optimisticCounts = Map<String, int>.from(state.postLikesCounts)..[postId] = newCount;
    state = state.copyWith(likedPostIds: optimisticLiked, postLikesCounts: optimisticCounts);

    try {
      final actionParam = targetLiked != null ? (targetLiked ? 'like' : 'unlike') : null;
      final url = actionParam != null
          ? '/posts/$postId/like?action=$actionParam'
          : '/posts/$postId/like';

      final response = await _apiClient.dio.post(url);
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          final serverLiked = data['isLikedByMe'] as bool? ?? data['likedByMe'] as bool? ?? data['liked'] as bool? ?? newLiked;
          final serverCount = (data['likesCount'] as num?)?.toInt() ?? newCount;
          debugPrint('[LIKE_POST] post=$postId server=$serverLiked count=$serverCount');

          final confirmedLiked = Map<String, bool>.from(state.likedPostIds)..[postId] = serverLiked;
          final confirmedCounts = Map<String, int>.from(state.postLikesCounts)..[postId] = serverCount;
          state = state.copyWith(likedPostIds: confirmedLiked, postLikesCounts: confirmedCounts);
        }
      }
    } catch (e) {
      debugPrint('[LIKE_POST] post=$postId rollback=true error=$e');
      final revertedLiked = Map<String, bool>.from(state.likedPostIds)..[postId] = currentlyLiked;
      final revertedCounts = Map<String, int>.from(state.postLikesCounts)..[postId] = currentCount;
      state = state.copyWith(likedPostIds: revertedLiked, postLikesCounts: revertedCounts);
    } finally {
      _inFlightLikes.remove(postId);
    }
  }

  Future<void> sharePost(String postId) async {
    final updated = state.posts.map((p) {
      if (p.id == postId) {
        return p.copyWith(sharesCount: p.sharesCount + 1);
      }
      return p;
    }).toList();

    state = state.copyWith(posts: updated);

    try {
      await _apiClient.dio.post('/posts/$postId/share');
    } catch (_) {}
  }
}

final postsProvider = StateNotifierProvider<PostsNotifier, PostsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PostsNotifier(apiClient);
});
