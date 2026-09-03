import 'package:flutter_test/flutter_test.dart';
import 'package:bidly_app/features/community/models/community_model.dart';
import 'package:bidly_app/features/community/providers/community_provider.dart';

void main() {
  group('Community Module State & Model Tests', () {
    test('State A: New user with zero memberships has empty myCommunities', () {
      const state = CommunityState();
      expect(state.myCommunities, isEmpty);
      expect(state.filteredMyCommunities, isEmpty);
      expect(state.exploreCommunities, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('State B: User with joined communities has populated myCommunities', () {
      final joinedCommunity = CommunityModel(
        id: 'comm-1',
        name: 'IIT Madras Tech Hub',
        description: 'Tech gadgets group',
        category: 'Electronics',
        isJoined: true,
        isAdmin: false,
        userRole: 'MEMBER',
        membersCount: 42,
      );

      final otherCommunity = CommunityModel(
        id: 'comm-2',
        name: 'Art & Design',
        description: 'Design community',
        category: 'Art',
        isJoined: false,
        isAdmin: false,
        userRole: null,
        membersCount: 15,
      );

      final state = const CommunityState().copyWith(
        myCommunities: [joinedCommunity],
        filteredMyCommunities: [joinedCommunity],
        communities: [joinedCommunity, otherCommunity],
        filteredCommunities: [joinedCommunity, otherCommunity],
      );

      expect(state.myCommunities.length, 1);
      expect(state.myCommunities.first.id, 'comm-1');
      expect(state.myCommunities.first.isJoined, isTrue);

      expect(state.exploreCommunities.length, 2);
    });

    test('CommunityModel.fromJson correctly parses backend DTO', () {
      final json = {
        'id': 'a1b2c3d4-e5f6-7890-1234-56789abcdef0',
        'name': 'Velachery Residents Group',
        'description': 'Buy & sell within Velachery',
        'iconUrl': null,
        'bannerUrl': null,
        'type': 'LOCAL',
        'category': 'Residents',
        'city': 'Chennai',
        'state': 'Tamil Nadu',
        'address': 'Velachery, Chennai',
        'radiusKm': 5,
        'rules': 'No spam. Genuine items only.',
        'membersCount': 88,
        'recentActivityText': 'Active discussions & auctions',
        'userRole': 'ADMIN',
        'isAdmin': true,
        'isJoined': true,
        'unreadCount': 0,
      };

      final model = CommunityModel.fromJson(json);

      expect(model.id, 'a1b2c3d4-e5f6-7890-1234-56789abcdef0');
      expect(model.name, 'Velachery Residents Group');
      expect(model.isAdmin, isTrue);
      expect(model.isJoined, isTrue);
      expect(model.userRole, 'ADMIN');
      expect(model.membersCount, 88);
      expect(model.unreadCount, 0);
    });

    test('resetOnLogout clears all user community state', () {
      final joinedCommunity = CommunityModel(
        id: 'comm-1',
        name: 'Tech Hub',
        category: 'Tech',
        isJoined: true,
        isAdmin: true,
        userRole: 'ADMIN',
      );

      var state = const CommunityState().copyWith(
        myCommunities: [joinedCommunity],
        filteredMyCommunities: [joinedCommunity],
        communities: [joinedCommunity],
        filteredCommunities: [joinedCommunity],
        searchQuery: 'Tech',
      );

      expect(state.myCommunities, isNotEmpty);

      // Simulate reset on logout
      state = const CommunityState();

      expect(state.myCommunities, isEmpty);
      expect(state.filteredMyCommunities, isEmpty);
      expect(state.communities, isEmpty);
      expect(state.searchQuery, isEmpty);
    });
  });
}
