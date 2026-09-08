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
  final Set<String> hiddenPostIds;
  final Set<String> restrictedUserIds;

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
    this.hiddenPostIds = const {},
    this.restrictedUserIds = const {},
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
    Set<String>? hiddenPostIds,
    Set<String>? restrictedUserIds,
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
      hiddenPostIds: hiddenPostIds ?? this.hiddenPostIds,
      restrictedUserIds: restrictedUserIds ?? this.restrictedUserIds,
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
  final Map<String, bool> _pendingTargetLikes = {};

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
    if (!mounted) return;
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
      if (!mounted) return;
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

        if (!mounted) return;
        state = state.copyWith(
          isLoading: false,
          posts: finalPosts,
          currentPage: 0,
          hasMore: fetchedPosts.length >= _pageSize,
          likedPostIds: newLiked,
          postLikesCounts: newCounts,
        );
      } else {
        if (!mounted) return;
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load posts',
        );
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to connect to feed server',
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (!mounted) return;
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _apiClient.dio.get('/posts?page=$nextPage&size=$_pageSize');
      if (!mounted) return;
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

        if (!mounted) return;
        state = state.copyWith(
          isLoadingMore: false,
          currentPage: nextPage,
          hasMore: newPosts.length >= _pageSize,
          posts: [...state.posts, ...uniqueNew],
          likedPostIds: newLiked,
          postLikesCounts: newCounts,
        );
      } else {
        if (!mounted) return;
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      }
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Toggle or ensure like on a post with idempotency, pending intent queueing, and optimistic update.
  Future<void> toggleLike(
    String postId,
    int serverLikesCount, {
    bool? targetLiked,
    bool initialLiked = false,
  }) async {
    final currentlyLiked = state.isLiked(postId, initialLiked);
    final currentCount = state.likesCount(postId, serverLikesCount);

    final newLiked = targetLiked ?? !currentlyLiked;
    if (targetLiked != null && targetLiked == currentlyLiked) {
      return;
    }

    final newCount = newLiked
        ? currentCount + 1
        : (currentCount > 0 ? currentCount - 1 : 0);

    debugPrint('[LIKE_POST] post=$postId action=${newLiked ? "like" : "unlike"} optimistic=$newLiked count=$newCount');

    // Optimistic UI update — targeted map update without rebuilding entire post list
    final optimisticLiked = Map<String, bool>.from(state.likedPostIds)..[postId] = newLiked;
    final optimisticCounts = Map<String, int>.from(state.postLikesCounts)..[postId] = newCount;
    state = state.copyWith(likedPostIds: optimisticLiked, postLikesCounts: optimisticCounts);

    // If already in-flight, queue this new target state and return immediately
    if (_inFlightLikes.contains(postId)) {
      _pendingTargetLikes[postId] = newLiked;
      debugPrint('[LIKE_POST] id=$postId queued pending target: $newLiked');
      return;
    }

    _inFlightLikes.add(postId);

    try {
      bool? nextDesired = newLiked;
      while (nextDesired != null) {
        final action = nextDesired ? 'like' : 'unlike';
        final url = '/posts/$postId/like?action=$action';
        _pendingTargetLikes.remove(postId);

        final response = await _apiClient.dio.post(url);
        if (response.data != null && response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>?;

          // If another tap occurred while this HTTP call was in-flight, continue loop with newest intent
          if (_pendingTargetLikes.containsKey(postId)) {
            nextDesired = _pendingTargetLikes[postId];
            continue;
          }

          if (data != null) {
            final serverLiked = data['isLikedByMe'] as bool? ??
                data['likedByMe'] as bool? ??
                data['liked'] as bool? ??
                nextDesired;
            final serverCount = (data['likesCount'] as num?)?.toInt() ?? state.likesCount(postId, newCount);
            debugPrint('[LIKE_POST] post=$postId server=$serverLiked count=$serverCount');

            final confirmedLiked = Map<String, bool>.from(state.likedPostIds)..[postId] = serverLiked;
            final confirmedCounts = Map<String, int>.from(state.postLikesCounts)..[postId] = serverCount;
            state = state.copyWith(likedPostIds: confirmedLiked, postLikesCounts: confirmedCounts);
          }
        }
        nextDesired = _pendingTargetLikes.remove(postId);
      }
    } catch (e) {
      debugPrint('[LIKE_POST] post=$postId rollback=true error=$e');
      if (!_pendingTargetLikes.containsKey(postId)) {
        final revertedLiked = Map<String, bool>.from(state.likedPostIds)..[postId] = currentlyLiked;
        final revertedCounts = Map<String, int>.from(state.postLikesCounts)..[postId] = currentCount;
        state = state.copyWith(likedPostIds: revertedLiked, postLikesCounts: revertedCounts);
      }
    } finally {
      _inFlightLikes.remove(postId);
      _pendingTargetLikes.remove(postId);
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

  /// Hide a post ("Not Interested") — instantly removes from local feed and persists to backend.
  Future<void> hidePost(String postId) async {
    // Optimistic: immediately remove from local list
    final updated = state.posts.where((p) => p.id != postId).toList();
    final newHidden = {...state.hiddenPostIds, postId};
    state = state.copyWith(posts: updated, hiddenPostIds: newHidden);
    debugPrint('[HIDE_POST] post=$postId removed from local feed');

    try {
      await _apiClient.dio.post('/posts/$postId/hide');
    } catch (e) {
      debugPrint('[HIDE_POST] API error: $e');
    }
  }

  /// Unhide a post ("Undo" Not Interested) — instantly re-inserts post and persists to backend.
  Future<void> unhidePost(String postId, {PostModel? restorePost, int? index}) async {
    final newHidden = Set<String>.from(state.hiddenPostIds)..remove(postId);
    List<PostModel> updated = List.from(state.posts);
    if (restorePost != null && !updated.any((p) => p.id == postId)) {
      if (index != null && index >= 0 && index <= updated.length) {
        updated.insert(index, restorePost);
      } else {
        updated.insert(0, restorePost);
      }
    }
    state = state.copyWith(posts: updated, hiddenPostIds: newHidden);
    debugPrint('[UNHIDE_POST] post=$postId restored to local feed');

    try {
      await _apiClient.dio.delete('/posts/$postId/hide');
    } catch (e) {
      debugPrint('[UNHIDE_POST] API error: $e');
    }
  }

  /// Restrict a user — instantly removes ALL their posts from local feed and persists to backend.
  Future<void> restrictUser(String authorId, String authorName) async {
    // Optimistic: immediately remove all posts by this author
    final updated = state.posts.where((p) => p.authorId != authorId).toList();
    final newRestricted = {...state.restrictedUserIds, authorId};
    state = state.copyWith(posts: updated, restrictedUserIds: newRestricted);
    debugPrint('[RESTRICT_USER] author=$authorId ($authorName) — removed ${state.posts.length - updated.length} posts');

    try {
      await _apiClient.dio.post('/posts/restrict/$authorId');
    } catch (e) {
      debugPrint('[RESTRICT_USER] API error: $e');
    }
  }

  /// Unrestrict a user — removes restriction and reloads feed.
  Future<void> unrestrictUser(String authorId) async {
    final newRestricted = Set<String>.from(state.restrictedUserIds)..remove(authorId);
    state = state.copyWith(restrictedUserIds: newRestricted);
    debugPrint('[UNRESTRICT_USER] author=$authorId unrestricted');

    try {
      await _apiClient.dio.delete('/posts/restrict/$authorId');
      await fetchFeed(isRefresh: true);
    } catch (e) {
      debugPrint('[UNRESTRICT_USER] API error: $e');
    }
  }
}

final postsProvider = StateNotifierProvider<PostsNotifier, PostsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PostsNotifier(apiClient);
});
