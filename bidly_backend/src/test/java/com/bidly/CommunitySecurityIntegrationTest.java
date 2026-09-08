package com.bidly;

import com.bidly.category.entity.Category;
import com.bidly.category.repository.CategoryRepository;
import com.bidly.common.exception.BidlyException;
import com.bidly.community.dto.*;
import com.bidly.community.entity.Community;
import com.bidly.community.entity.CommunityMember;
import com.bidly.community.entity.CommunityPost;
import com.bidly.community.repository.CommunityMemberRepository;
import com.bidly.community.repository.CommunityMuteRepository;
import com.bidly.community.repository.CommunityPostRepository;
import com.bidly.community.repository.CommunityRepository;
import com.bidly.community.repository.PostHideRepository;
import com.bidly.community.repository.PostLikeRepository;
import com.bidly.community.repository.UserRestrictRepository;
import com.bidly.community.service.CommunityPostService;
import com.bidly.community.service.CommunityService;
import com.bidly.listing.dto.CreateListingRequest;
import com.bidly.listing.dto.ListingSummaryDto;
import com.bidly.listing.entity.Listing;
import com.bidly.listing.repository.ListingLikeRepository;
import com.bidly.listing.repository.ListingMediaRepository;
import com.bidly.listing.repository.ListingRepository;
import com.bidly.listing.service.ListingService;
import com.bidly.media.repository.MediaJobRepository;
import com.bidly.media.service.MediaService;
import com.bidly.user.entity.User;
import com.bidly.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;

import java.math.BigDecimal;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class CommunitySecurityIntegrationTest {

    @Mock private CommunityRepository communityRepository;
    @Mock private CommunityMemberRepository memberRepository;
    @Mock private CommunityMuteRepository communityMuteRepository;
    @Mock private CommunityPostRepository postRepository;
    @Mock private PostLikeRepository postLikeRepository;
    @Mock private PostHideRepository postHideRepository;
    @Mock private UserRestrictRepository userRestrictRepository;
    @Mock private UserRepository userRepository;
    @Mock private ListingRepository listingRepository;
    @Mock private ListingMediaRepository mediaRepository;
    @Mock private ListingLikeRepository listingLikeRepository;
    @Mock private CategoryRepository categoryRepository;
    @Mock private MediaService mediaService;
    @Mock private MediaJobRepository mediaJobRepository;

    private CommunityService communityService;
    private CommunityPostService postService;
    private ListingService listingService;

    private User userA; // Creator of Community A
    private User userB; // Regular user / prospective member
    private Community communityA;
    private CommunityPost postA;
    private Listing listingA;

    @BeforeEach
    void setUp() {
        communityService = new CommunityService(communityRepository, memberRepository, communityMuteRepository, userRepository);
        postService = new CommunityPostService(postRepository, communityRepository, memberRepository, postLikeRepository, postHideRepository, userRestrictRepository, userRepository, mediaService);
        listingService = new ListingService(
                listingRepository,
                mediaRepository,
                listingLikeRepository,
                categoryRepository,
                userRepository,
                communityRepository,
                memberRepository,
                postRepository,
                mediaService,
                mediaJobRepository
        );

        userA = new User();
        userA.setId(UUID.fromString("11111111-1111-1111-1111-111111111111"));
        userA.setName("User A");
        userA.setPhone("9876543210");

        userB = new User();
        userB.setId(UUID.fromString("22222222-2222-2222-2222-222222222222"));
        userB.setName("User B");
        userB.setPhone("9876543211");

        communityA = new Community();
        communityA.setId(UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"));
        communityA.setName("Tech Campus Group");
        communityA.setDescription("Official tech gadgets group");
        communityA.setCreatedBy(userA.getId());
        communityA.setActive(true);
        communityA.setMembersCount(1);

        postA = new CommunityPost();
        postA.setId(UUID.fromString("33333333-3333-3333-3333-333333333333"));
        postA.setAuthor(userA);
        postA.setCommunity(communityA);
        postA.setContent("MacBook Pro M3 • ₹95,000");
        postA.setTag("SELLING");

        listingA = new Listing();
        listingA.setId(UUID.fromString("44444444-4444-4444-4444-444444444444"));
        listingA.setSeller(userA);
        listingA.setCommunityId(communityA.getId());
        listingA.setCommunityName(communityA.getName());
        listingA.setTitle("MacBook Pro M3");
        listingA.setPrice(BigDecimal.valueOf(95000.00));
        listingA.setStatus(Listing.ListingStatus.ACTIVE);
    }

    @Test
    @DisplayName("TEST 1 — New user with 0 memberships sees empty My Communities list")
    void test1_newUser_zeroMemberships_returnsEmptyList() {
        when(memberRepository.findByUserId(userB.getId())).thenReturn(Collections.emptyList());

        List<CommunityDto> result = communityService.getMyCommunities(userB.getId());

        assertNotNull(result);
        assertTrue(result.isEmpty());
        verify(memberRepository, times(1)).findByUserId(userB.getId());
    }

    @Test
    @DisplayName("TEST 2 — User A creates Community A: becomes creator, ADMIN, and ACTIVE member")
    void test2_createCommunity_creatorBecomesAdminAndMember() {
        CreateCommunityRequest request = new CreateCommunityRequest();
        request.setName("Tech Campus Group");
        request.setDescription("Official tech gadgets group");
        request.setCategory("Electronics");
        request.setRadiusKm(10);

        when(communityRepository.save(any(Community.class))).thenAnswer(inv -> {
            Community c = inv.getArgument(0);
            c.setId(communityA.getId());
            return c;
        });

        CommunityDto created = communityService.createCommunity(userA.getId(), request);

        assertNotNull(created);
        assertEquals(communityA.getId(), created.getId());
        assertEquals("ADMIN", created.getUserRole());
        assertTrue(created.isAdmin());
        assertTrue(created.isJoined());

        // Verify member repository persisted creator as ADMIN
        ArgumentCaptor<CommunityMember> memberCaptor = ArgumentCaptor.forClass(CommunityMember.class);
        verify(memberRepository, times(1)).save(memberCaptor.capture());
        CommunityMember savedMember = memberCaptor.getValue();
        assertEquals(communityA.getId(), savedMember.getCommunityId());
        assertEquals(userA.getId(), savedMember.getUserId());
        assertEquals("ADMIN", savedMember.getRole());
    }

    @Test
    @DisplayName("TEST 3 — Non-member User B cannot access Community A posts or post details (403 Forbidden)")
    void test3_nonMember_accessCommunityPosts_forbidden() {
        when(communityRepository.findById(communityA.getId())).thenReturn(Optional.of(communityA));
        when(memberRepository.existsByCommunityIdAndUserId(communityA.getId(), userB.getId())).thenReturn(false);

        // Access community feed directly
        BidlyException ex1 = assertThrows(BidlyException.class, () ->
                postService.getCommunityPosts(communityA.getId(), userB.getId(), 0, 20));
        assertEquals(HttpStatus.FORBIDDEN, ex1.getStatus());

        // Access single community post by ID directly
        when(postRepository.findById(postA.getId())).thenReturn(Optional.of(postA));
        BidlyException ex2 = assertThrows(BidlyException.class, () ->
                postService.getPostById(postA.getId(), userB.getId()));
        assertEquals(HttpStatus.FORBIDDEN, ex2.getStatus());
    }

    @Test
    @DisplayName("TEST 4 — Non-member User B cannot access Community A listing details (403 Forbidden)")
    void test4_nonMember_accessCommunityListing_forbidden() {
        when(listingRepository.findById(listingA.getId())).thenReturn(Optional.of(listingA));
        when(memberRepository.existsByCommunityIdAndUserId(communityA.getId(), userB.getId())).thenReturn(false);

        BidlyException ex = assertThrows(BidlyException.class, () ->
                listingService.getListingById(listingA.getId(), userB.getId()));
        assertEquals(HttpStatus.FORBIDDEN, ex.getStatus());
    }

    @Test
    @DisplayName("TEST 5 — Non-member User B cannot create a post in Community A (403 Forbidden)")
    void test5_nonMember_createPost_forbidden() {
        CreatePostRequest request = new CreatePostRequest();
        request.setCommunityId(communityA.getId());
        request.setContent("Want to sell wireless headphones");

        when(userRepository.findById(userB.getId())).thenReturn(Optional.of(userB));
        when(communityRepository.findById(communityA.getId())).thenReturn(Optional.of(communityA));
        when(memberRepository.existsByCommunityIdAndUserId(communityA.getId(), userB.getId())).thenReturn(false);

        BidlyException ex = assertThrows(BidlyException.class, () ->
                postService.createPost(userB.getId(), request));
        assertEquals(HttpStatus.FORBIDDEN, ex.getStatus());
    }

    @Test
    @DisplayName("TEST 6 — Non-member User B cannot create a listing in Community A (403 Forbidden)")
    void test6_nonMember_createListing_forbidden() {
        CreateListingRequest request = new CreateListingRequest();
        request.setCommunityId(communityA.getId());
        request.setTitle("Wireless Headphones");
        request.setDescription("Original condition");
        request.setCategory("Electronics");
        request.setPrice(BigDecimal.valueOf(2500.00));
        request.setSellingMethod("DIRECT_BUY");

        Category testCat = new Category("Electronics", null, 1, null, true);
        when(categoryRepository.findFirstByNameIgnoreCase(any())).thenReturn(Optional.of(testCat));
        when(userRepository.findById(userB.getId())).thenReturn(Optional.of(userB));
        when(communityRepository.findById(communityA.getId())).thenReturn(Optional.of(communityA));
        when(memberRepository.existsByCommunityIdAndUserId(communityA.getId(), userB.getId())).thenReturn(false);

        BidlyException ex = assertThrows(BidlyException.class, () ->
                listingService.createListing(userB.getId(), request));
        assertEquals(HttpStatus.FORBIDDEN, ex.getStatus());
    }

    @Test
    @DisplayName("TEST 7 — Non-admin joined member User B cannot perform admin operations (403 Forbidden)")
    void test7_nonAdmin_adminOperations_forbidden() {
        when(communityRepository.findById(communityA.getId())).thenReturn(Optional.of(communityA));
        when(memberRepository.existsByCommunityIdAndUserIdAndRole(communityA.getId(), userB.getId(), "ADMIN")).thenReturn(false);

        // Attempt add member
        AddMemberRequest addReq = new AddMemberRequest();
        addReq.setPhone("9999999999");
        BidlyException exAdd = assertThrows(BidlyException.class, () ->
                communityService.addMember(communityA.getId(), userB.getId(), addReq));
        assertEquals(HttpStatus.FORBIDDEN, exAdd.getStatus());

        // Attempt edit community info
        CreateCommunityRequest updateReq = new CreateCommunityRequest();
        updateReq.setName("New Hacked Name");
        BidlyException exUpdate = assertThrows(BidlyException.class, () ->
                communityService.updateCommunity(communityA.getId(), userB.getId(), updateReq));
        assertEquals(HttpStatus.FORBIDDEN, exUpdate.getStatus());

        // Attempt remove another user
        UUID thirdUserId = UUID.randomUUID();
        BidlyException exRemove = assertThrows(BidlyException.class, () ->
                communityService.removeMember(communityA.getId(), userB.getId(), thirdUserId));
        assertEquals(HttpStatus.FORBIDDEN, exRemove.getStatus());
    }

    @Test
    @DisplayName("TEST 8 — User B joins Community A: gains access to posts and listings")
    void test8_userB_joinsCommunityA_accessGranted() {
        when(communityRepository.findById(communityA.getId())).thenReturn(Optional.of(communityA));
        when(memberRepository.existsByCommunityIdAndUserId(communityA.getId(), userB.getId())).thenReturn(false, true);

        // Join
        communityService.joinCommunity(communityA.getId(), userB.getId());
        verify(memberRepository, times(1)).save(any(CommunityMember.class));

        // Now view community posts
        when(postRepository.findByCommunityIdOrderByCreatedAtDesc(eq(communityA.getId()), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(postA)));
        List<PostDto> posts = postService.getCommunityPosts(communityA.getId(), userB.getId(), 0, 20);
        assertEquals(1, posts.size());
        assertEquals("MacBook Pro M3 • ₹95,000", posts.get(0).getContent());

        // Now view post by ID
        when(postRepository.findById(postA.getId())).thenReturn(Optional.of(postA));
        PostDto singlePost = postService.getPostById(postA.getId(), userB.getId());
        assertNotNull(singlePost);
        assertEquals(postA.getId(), singlePost.getId());

        // Now view listing by ID
        when(listingRepository.findById(listingA.getId())).thenReturn(Optional.of(listingA));
        ListingSummaryDto singleListing = listingService.getListingById(listingA.getId(), userB.getId());
        assertNotNull(singleListing);
        assertEquals(listingA.getId(), singleListing.getId());
    }

    @Test
    @DisplayName("TEST 9 — Regular member cannot post listings/posts; only creator/admin can")
    void test9_onlyCreatorCanPostListingsAndPosts() {
        // User B (joined regular member) attempts createPost -> forbidden
        CreatePostRequest postReq = new CreatePostRequest();
        postReq.setCommunityId(communityA.getId());
        postReq.setContent("Member post attempt");

        when(userRepository.findById(userB.getId())).thenReturn(Optional.of(userB));
        when(communityRepository.findById(communityA.getId())).thenReturn(Optional.of(communityA));
        when(memberRepository.existsByCommunityIdAndUserId(communityA.getId(), userB.getId())).thenReturn(true);
        when(memberRepository.existsByCommunityIdAndUserIdAndRole(communityA.getId(), userB.getId(), "ADMIN")).thenReturn(false);

        BidlyException exPost = assertThrows(BidlyException.class, () ->
                postService.createPost(userB.getId(), postReq));
        assertEquals(HttpStatus.FORBIDDEN, exPost.getStatus());

        // User B (joined regular member) attempts createListing -> forbidden
        CreateListingRequest listReq = new CreateListingRequest();
        listReq.setCommunityId(communityA.getId());
        listReq.setTitle("Member item");
        listReq.setDescription("Member item description");
        listReq.setCategory("Electronics");
        listReq.setPrice(BigDecimal.valueOf(1000.00));

        Category testCat = new Category("Electronics", null, 1, null, true);
        when(categoryRepository.findFirstByNameIgnoreCase(any())).thenReturn(Optional.of(testCat));

        BidlyException exList = assertThrows(BidlyException.class, () ->
                listingService.createListing(userB.getId(), listReq));
        assertEquals(HttpStatus.FORBIDDEN, exList.getStatus());

        // User A (creator) creates post -> succeeds
        when(userRepository.findById(userA.getId())).thenReturn(Optional.of(userA));
        when(postRepository.save(any(CommunityPost.class))).thenAnswer(inv -> inv.getArgument(0));
        CreatePostRequest creatorPostReq = new CreatePostRequest();
        creatorPostReq.setCommunityId(communityA.getId());
        creatorPostReq.setContent("Creator announcement post");

        PostDto createdPost = postService.createPost(userA.getId(), creatorPostReq);
        assertNotNull(createdPost);
        assertEquals("Creator announcement post", createdPost.getContent());
    }

    @Test
    @DisplayName("TEST 10 — User B leaves Community A: community absent from My Communities, access revoked")
    void test10_userB_leavesCommunityA_accessRevoked() {
        when(communityRepository.findById(communityA.getId())).thenReturn(Optional.of(communityA));

        // User B leaves
        communityService.leaveCommunity(communityA.getId(), userB.getId());
        verify(memberRepository, times(1)).deleteByCommunityIdAndUserId(communityA.getId(), userB.getId());

        // Now membership check returns false
        when(memberRepository.existsByCommunityIdAndUserId(communityA.getId(), userB.getId())).thenReturn(false);

        // Community feed access revoked
        BidlyException exFeed = assertThrows(BidlyException.class, () ->
                postService.getCommunityPosts(communityA.getId(), userB.getId(), 0, 20));
        assertEquals(HttpStatus.FORBIDDEN, exFeed.getStatus());

        // Single post access revoked
        when(postRepository.findById(postA.getId())).thenReturn(Optional.of(postA));
        BidlyException exPost = assertThrows(BidlyException.class, () ->
                postService.getPostById(postA.getId(), userB.getId()));
        assertEquals(HttpStatus.FORBIDDEN, exPost.getStatus());

        // Single listing access revoked
        when(listingRepository.findById(listingA.getId())).thenReturn(Optional.of(listingA));
        BidlyException exList = assertThrows(BidlyException.class, () ->
                listingService.getListingById(listingA.getId(), userB.getId()));
        assertEquals(HttpStatus.FORBIDDEN, exList.getStatus());
    }

    @Test
    @DisplayName("TEST 11 — Creator User A cannot leave own community (400 Bad Request)")
    void test11_creator_cannotLeaveOwnCommunity() {
        when(communityRepository.findById(communityA.getId())).thenReturn(Optional.of(communityA));

        BidlyException ex = assertThrows(BidlyException.class, () ->
                communityService.leaveCommunity(communityA.getId(), userA.getId()));

        assertEquals(HttpStatus.BAD_REQUEST, ex.getStatus());
        assertEquals("Community creator cannot leave their own community", ex.getMessage());
        verify(memberRepository, never()).deleteByCommunityIdAndUserId(any(), any());
    }
}
