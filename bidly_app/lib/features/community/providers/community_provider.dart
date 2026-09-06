import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/community_member_model.dart';
import '../models/community_model.dart';

class CommunityState {
  final bool isLoading;
  final bool isCreating;
  final String? errorMessage;
  final List<CommunityModel> myCommunities;
  final List<CommunityModel> filteredMyCommunities;
  final List<CommunityModel> communities; // Explore communities
  final List<CommunityModel> filteredCommunities; // Filtered explore communities
  final String searchQuery;
  final CommunityModel? selectedCommunity;
  final List<CommunityMemberModel> members;

  const CommunityState({
    this.isLoading = false,
    this.isCreating = false,
    this.errorMessage,
    this.myCommunities = const [],
    this.filteredMyCommunities = const [],
    this.communities = const [],
    this.filteredCommunities = const [],
    this.searchQuery = '',
    this.selectedCommunity,
    this.members = const [],
  });

  CommunityState copyWith({
    bool? isLoading,
    bool? isCreating,
    String? errorMessage,
    List<CommunityModel>? myCommunities,
    List<CommunityModel>? filteredMyCommunities,
    List<CommunityModel>? communities,
    List<CommunityModel>? filteredCommunities,
    String? searchQuery,
    CommunityModel? selectedCommunity,
    List<CommunityMemberModel>? members,
  }) {
    return CommunityState(
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      errorMessage: errorMessage,
      myCommunities: myCommunities ?? this.myCommunities,
      filteredMyCommunities: filteredMyCommunities ?? this.filteredMyCommunities,
      communities: communities ?? this.communities,
      filteredCommunities: filteredCommunities ?? this.filteredCommunities,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCommunity: selectedCommunity ?? this.selectedCommunity,
      members: members ?? this.members,
    );
  }

  List<CommunityModel> get exploreCommunities => communities;
  List<CommunityModel> get filteredExploreCommunities => filteredCommunities;
}

class CommunityNotifier extends StateNotifier<CommunityState> {
  final ApiClient _apiClient;

  CommunityNotifier(this._apiClient) : super(const CommunityState()) {
    fetchCommunities();
  }

  /// Fetch both my communities (joined/created) and explore communities
  Future<void> fetchCommunities({bool isRefresh = false}) async {
    if (state.myCommunities.isEmpty && state.communities.isEmpty) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      // 1. Fetch user's joined/owned communities from backend
      List<CommunityModel> myComms = [];
      try {
        final myRes = await _apiClient.dio.get('/communities/my');
        if (myRes.data != null && myRes.data['success'] == true) {
          myComms = (myRes.data['data'] as List)
              .map((item) => CommunityModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {
        // Unauthenticated or error -> myComms remains empty
      }

      // 2. Fetch all discoverable communities for Explore
      List<CommunityModel> allComms = [];
      final exploreRes = await _apiClient.dio.get('/communities');
      if (exploreRes.data != null && exploreRes.data['success'] == true) {
        allComms = (exploreRes.data['data'] as List)
            .map((item) => CommunityModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      state = state.copyWith(
        isLoading: false,
        myCommunities: myComms,
        filteredMyCommunities: _applySearch(myComms, state.searchQuery),
        communities: allComms,
        filteredCommunities: _applySearch(allComms, state.searchQuery),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to connect to server',
      );
    }
  }

  /// Reset state on logout so user data does not leak
  void resetOnLogout() {
    state = const CommunityState();
  }

  /// Filter communities by search query
  void searchCommunities(String query) {
    state = state.copyWith(
      searchQuery: query,
      filteredMyCommunities: _applySearch(state.myCommunities, query),
      filteredCommunities: _applySearch(state.communities, query),
    );
  }

  List<CommunityModel> _applySearch(List<CommunityModel> list, String query) {
    if (query.trim().isEmpty) return list;
    final q = query.trim().toLowerCase();
    return list.where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.description != null && c.description!.toLowerCase().contains(q)) ||
          c.category.toLowerCase().contains(q) ||
          (c.city != null && c.city!.toLowerCase().contains(q));
    }).toList();
  }

  /// Create a new community
  Future<CommunityModel?> createCommunity({
    required String name,
    required String description,
    required String category,
    required String address,
    required int radiusKm,
    String? rules,
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isCreating: true, errorMessage: null);

    final payload = {
      'name': name.trim(),
      'description': description.trim(),
      'category': category,
      'address': address.trim(),
      'radiusKm': radiusKm,
      'rules': rules?.trim(),
      'latitude': latitude,
      'longitude': longitude,
    };

    try {
      final response = await _apiClient.dio.post('/communities', data: payload);

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final created = CommunityModel.fromJson(data);

        final updatedList = [created, ...state.communities];
        state = state.copyWith(
          isCreating: false,
          communities: updatedList,
          filteredCommunities: _applySearch(updatedList, state.searchQuery),
          selectedCommunity: created,
        );
        return created;
      } else {
        final msg = response.data?['message']?.toString() ?? 'Failed to create community';
        state = state.copyWith(isCreating: false, errorMessage: msg);
        return null;
      }
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message']?.toString();
      final msg = serverMsg ?? 'Unable to reach backend server. Please make sure backend is restarted and running.';
      state = state.copyWith(
        isCreating: false,
        errorMessage: msg,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: 'Network error occurred while creating community.',
      );
      return null;
    }
  }

  /// Fetch members of a community
  Future<void> fetchMembers(String communityId) async {
    try {
      final response = await _apiClient.dio.get('/communities/$communityId/members');
      if (response.data != null && response.data['success'] == true) {
        final list = (response.data['data'] as List)
            .map((item) => CommunityMemberModel.fromJson(item as Map<String, dynamic>))
            .toList();
        state = state.copyWith(members: list);
      }
    } catch (_) {}
  }

  /// Admin adds member by phone number
  Future<bool> addMember({
    required String communityId,
    required String phone,
    String role = 'MEMBER',
  }) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final normalized = cleanPhone.length > 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;

      final response = await _apiClient.dio.post(
        '/communities/$communityId/members',
        data: {'phone': normalized, 'role': role},
      );

      if (response.data != null && response.data['success'] == true) {
        await fetchMembers(communityId);
        await fetchCommunities();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Admin removes a member from community
  Future<bool> removeMember({
    required String communityId,
    required String targetUserId,
  }) async {
    try {
      final response = await _apiClient.dio.delete(
        '/communities/$communityId/members/$targetUserId',
      );

      if (response.data != null && response.data['success'] == true) {
        await fetchMembers(communityId);
        await fetchCommunities();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Join community as regular member
  Future<bool> joinCommunity(String communityId) async {
    try {
      final response = await _apiClient.dio.post('/communities/$communityId/join');
      if (response.data != null && response.data['success'] == true) {
        await fetchCommunities(isRefresh: true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Leave community as authenticated member
  Future<bool> leaveCommunity(String communityId) async {
    try {
      final response = await _apiClient.dio.post('/communities/$communityId/leave');
      if (response.data != null && response.data['success'] == true) {
        await fetchCommunities(isRefresh: true);
        if (state.selectedCommunity?.id == communityId) {
          state = state.copyWith(selectedCommunity: null, members: []);
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Fetch real-time posts for a community
  Future<List<Map<String, dynamic>>> fetchCommunityPosts(String communityId) async {
    try {
      final response = await _apiClient.dio.get('/posts/community/$communityId');
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list.map((item) {
          final map = item as Map<String, dynamic>;
          final tag = map['tag']?.toString() ?? 'DIRECT';
          final rawContent = map['content']?.toString() ?? '';

          // Parse "Title • ₹Price\nDescription" format
          String title = rawContent;
          String priceText = '';
          String description = '';

          // Split by newline first to separate description
          final lines = rawContent.split('\n');
          final firstLine = lines.isNotEmpty ? lines[0] : rawContent;
          description = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';

          // Split first line by " • " to separate title and price
          if (firstLine.contains(' • ')) {
            final parts = firstLine.split(' • ');
            title = parts[0].trim();
            priceText = parts.length > 1 ? parts[1].trim() : '';
          } else {
            title = firstLine.trim();
          }

          // If description was on the same line after price (e.g. "₹89.0 Description text")
          if (description.isEmpty && priceText.contains(' ')) {
            final spaceIdx = priceText.indexOf(' ');
            final firstToken = priceText.substring(0, spaceIdx).trim();
            final rest = priceText.substring(spaceIdx).trim();
            if (firstToken.startsWith('₹') || RegExp(r'^\d').hasMatch(firstToken)) {
              priceText = firstToken;
              description = rest;
            }
          }

          // Clean up .0 or .00 from price (e.g. ₹89.0 -> ₹89)
          if (priceText.contains('.0') || priceText.contains('.00')) {
            priceText = priceText.replaceAll(RegExp(r'\.00?(?!\d)'), '');
          }

          // If price starts with "Starts" for auction, prefix correctly
          if (tag == 'AUCTION' && priceText.isNotEmpty && !priceText.startsWith('Starts')) {
            priceText = 'Starts $priceText';
          }

          // Calculate timeAgo from createdAt
          String timeAgo = 'Recently';
          if (map['createdAt'] != null) {
            try {
              final createdAt = DateTime.parse(map['createdAt'].toString());
              final diff = DateTime.now().toUtc().difference(createdAt);
              if (diff.inMinutes < 1) {
                timeAgo = 'Just now';
              } else if (diff.inMinutes < 60) {
                timeAgo = '${diff.inMinutes}m ago';
              } else if (diff.inHours < 24) {
                timeAgo = '${diff.inHours}h ago';
              } else if (diff.inDays < 7) {
                timeAgo = '${diff.inDays}d ago';
              } else {
                timeAgo = '${(diff.inDays / 7).floor()}w ago';
              }
            } catch (_) {}
          }

          final rawListingTitle = map['listingTitle']?.toString();
          final rawListingDesc = map['listingDescription']?.toString();
          final finalTitle = (rawListingTitle != null && rawListingTitle.trim().isNotEmpty) ? rawListingTitle.trim() : title;
          final finalDescription = (rawListingDesc != null && rawListingDesc.trim().isNotEmpty) ? rawListingDesc.trim() : description;

          return {
            'id': map['id']?.toString() ?? '',
            'listingId': map['listingId']?.toString(),
            'authorId': map['authorId']?.toString(),
            'authorName': map['authorName']?.toString() ?? 'Member',
            'authorAvatarUrl': map['authorAvatarUrl']?.toString(),
            'timeAgo': timeAgo,
            'sellingMethod': (map['sellingMethod']?.toString() ?? tag) == 'AUCTION' ? 'AUCTION' : 'DIRECT',
            'title': finalTitle,
            'priceText': priceText,
            'price': map['price'],
            'startingBid': map['startingBid'],
            'currentBid': map['currentBid'],
            'bidsCount': map['bidsCount'] as int? ?? 0,
            'auctionEndTime': map['auctionEndTime']?.toString(),
            'distanceKm': (map['distanceKm'] as num?)?.toDouble() ?? 2.0,
            'description': finalDescription,
            'imageUrl': map['mediaUrl']?.toString(),
            'likesCount': map['likesCount'] as int? ?? 0,
            'sharesCount': map['sharesCount'] as int? ?? 0,
            'isLiked': (map['likedByMe'] ?? map['isLikedByMe']) as bool? ?? false,
          };
        }).toList();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        // Access forbidden: user is not an active member
        return [];
      }
    } catch (_) {}
    return [];
  }

  /// Toggle like on a community post (calls backend)
  Future<bool?> likePost(String postId) async {
    try {
      final response = await _apiClient.dio.post('/posts/$postId/like');
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return data['liked'] as bool?;
      }
    } catch (_) {}
    return null;
  }

  /// Increment share count on a community post (calls backend)
  Future<int?> sharePost(String postId) async {
    try {
      final response = await _apiClient.dio.post('/posts/$postId/share');
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return data['sharesCount'] as int?;
      }
    } catch (_) {}
    return null;
  }

  /// Create a real-time post for a community
  Future<bool> createCommunityPost({
    required String communityId,
    required String content,
    String? mediaUrl,
    String tag = 'SELLING',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/posts',
        data: {
          'communityId': communityId,
          'content': content,
          'mediaUrl': mediaUrl,
          'tag': tag,
        },
      );
      return response.data != null && response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Update community details (Admin only)
  Future<CommunityModel?> updateCommunity({
    required String communityId,
    required String name,
    String? description,
    String? category,
    String? rules,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/communities/$communityId',
        data: {
          'name': name,
          'description': description,
          'category': category,
          'rules': rules,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final updated = CommunityModel.fromJson(response.data['data'] as Map<String, dynamic>);
        final updatedList = state.communities.map((c) => c.id == updated.id ? updated : c).toList();
        state = state.copyWith(
          communities: updatedList,
          filteredCommunities: _applySearch(updatedList, state.searchQuery),
          selectedCommunity: updated,
        );
        return updated;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void selectCommunity(CommunityModel community) {
    state = state.copyWith(selectedCommunity: community);
    fetchMembers(community.id);
  }

  /// Sync device phone numbers with backend to find Bidly users
  Future<List<Map<String, dynamic>>> syncContacts(List<String> phoneNumbers) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/sync-contacts',
        data: {'phoneNumbers': phoneNumbers},
      );
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list.map((item) => item as Map<String, dynamic>).toList();
      }
    } catch (_) {}
    return [];
  }
}

final communityProvider = StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  ref.watch(authProvider);
  return CommunityNotifier(apiClient);
});
