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

  const PostsState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.posts = const [],
    this.activeTab = 1,
    this.currentPage = 0,
    this.hasMore = true,
  });

  PostsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    List<PostModel>? posts,
    int? activeTab,
    int? currentPage,
    bool? hasMore,
  }) {
    return PostsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      posts: posts ?? this.posts,
      activeTab: activeTab ?? this.activeTab,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class PostsNotifier extends StateNotifier<PostsState> {
  final ApiClient _apiClient;
  static const int _pageSize = 10;

  PostsNotifier(this._apiClient) : super(const PostsState()) {
    fetchFeed();
  }

  void setActiveTab(int index) {
    state = state.copyWith(activeTab: index);
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
        state = state.copyWith(
          isLoading: false,
          posts: fetchedPosts,
          currentPage: 0,
          hasMore: fetchedPosts.length >= _pageSize,
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

        state = state.copyWith(
          isLoadingMore: false,
          currentPage: nextPage,
          hasMore: newPosts.length >= _pageSize,
          posts: [...state.posts, ...uniqueNew],
        );
      } else {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      }
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> toggleLike(String postId) async {
    // Snapshot old state for rollback
    final originalPost = state.posts.firstWhere((p) => p.id == postId, orElse: () => state.posts.first);
    final previouslyLiked = originalPost.isLikedByMe;
    final previousCount = originalPost.likesCount;

    final newLiked = !previouslyLiked;
    final newCount = newLiked ? previousCount + 1 : (previousCount > 0 ? previousCount - 1 : 0);

    // Optimistic UI update
    final updated = state.posts.map((p) {
      if (p.id == postId) {
        return p.copyWith(isLikedByMe: newLiked, likesCount: newCount);
      }
      return p;
    }).toList();

    state = state.copyWith(posts: updated);

    try {
      final response = await _apiClient.dio.post('/posts/$postId/like');
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null && data['liked'] != null) {
          final serverLiked = data['liked'] as bool;
          if (serverLiked != newLiked) {
            final confirmed = state.posts.map((p) {
              if (p.id == postId) {
                return p.copyWith(isLikedByMe: serverLiked);
              }
              return p;
            }).toList();
            state = state.copyWith(posts: confirmed);
          }
        }
      }
    } catch (_) {
      // Revert if API fails
      final reverted = state.posts.map((p) {
        if (p.id == postId) {
          return p.copyWith(isLikedByMe: previouslyLiked, likesCount: previousCount);
        }
        return p;
      }).toList();
      state = state.copyWith(posts: reverted);
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
