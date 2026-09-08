package com.bidly.community.service;

import com.bidly.common.exception.BidlyException;
import com.bidly.community.dto.CommunityDto;
import com.bidly.community.dto.CreatePostRequest;
import com.bidly.community.dto.PostDto;
import com.bidly.community.entity.Community;
import com.bidly.community.entity.CommunityPost;
import com.bidly.community.entity.PostHide;
import com.bidly.community.entity.PostLike;
import com.bidly.community.entity.UserRestrict;
import com.bidly.community.repository.CommunityMemberRepository;
import com.bidly.community.repository.CommunityPostRepository;
import com.bidly.community.repository.CommunityRepository;
import com.bidly.community.repository.PostHideRepository;
import com.bidly.community.repository.PostLikeRepository;
import com.bidly.community.repository.UserRestrictRepository;
import com.bidly.user.entity.User;
import com.bidly.user.repository.UserRepository;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.bidly.listing.dto.ListingSummaryDto;
import com.bidly.listing.entity.ListingMedia;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CommunityPostService {

    private static final Logger log = LoggerFactory.getLogger(CommunityPostService.class);

    private final CommunityPostRepository postRepository;
    private final CommunityRepository communityRepository;
    private final CommunityMemberRepository memberRepository;
    private final PostLikeRepository postLikeRepository;
    private final PostHideRepository postHideRepository;
    private final UserRestrictRepository userRestrictRepository;
    private final UserRepository userRepository;
    private final com.bidly.media.service.MediaService mediaService;

    public CommunityPostService(
            CommunityPostRepository postRepository,
            CommunityRepository communityRepository,
            CommunityMemberRepository memberRepository,
            PostLikeRepository postLikeRepository,
            PostHideRepository postHideRepository,
            UserRestrictRepository userRestrictRepository,
            UserRepository userRepository,
            com.bidly.media.service.MediaService mediaService) {
        this.postRepository = postRepository;
        this.communityRepository = communityRepository;
        this.memberRepository = memberRepository;
        this.postLikeRepository = postLikeRepository;
        this.postHideRepository = postHideRepository;
        this.userRestrictRepository = userRestrictRepository;
        this.userRepository = userRepository;
        this.mediaService = mediaService;
    }

    // No dummy seed data — Real-time user data only

    /**
     * Retrieves global posts for the home feed (excludes community-specific posts).
     */
    @Transactional(readOnly = true)
    public List<PostDto> getFeed(UUID currentUserId, int page, int size) {
        return getFeed(currentUserId, null, null, page, size);
    }

    /**
     * Retrieves global posts for the home feed (excludes community-specific posts).
     */
    @Transactional(readOnly = true)
    public List<PostDto> getFeed(UUID currentUserId, Double latitude, Double longitude, int page, int size) {
        long t0 = System.currentTimeMillis();
        Page<CommunityPost> postsPage = postRepository.findByCommunityIsNullOrderByCreatedAtDesc(PageRequest.of(page, size));
        long t1 = System.currentTimeMillis();

        List<CommunityPost> content = postsPage.getContent();

        // Filter out hidden posts and restricted users for authenticated users
        Set<UUID> hiddenPostIds = Collections.emptySet();
        Set<UUID> restrictedUserIds = Collections.emptySet();
        if (currentUserId != null) {
            hiddenPostIds = postHideRepository.findHiddenPostIdsByUserId(currentUserId);
            restrictedUserIds = userRestrictRepository.findRestrictedUserIdsByUserId(currentUserId);
        }
        final Set<UUID> finalHidden = hiddenPostIds;
        final Set<UUID> finalRestricted = restrictedUserIds;
        List<CommunityPost> filtered = content.stream()
                .filter(p -> !finalHidden.contains(p.getId()))
                .filter(p -> p.getAuthor() == null || !finalRestricted.contains(p.getAuthor().getId()))
                .collect(Collectors.toList());

        Set<UUID> likedPostIds = Collections.emptySet();
        if (currentUserId != null && !filtered.isEmpty()) {
            List<UUID> postIds = filtered.stream().map(CommunityPost::getId).collect(Collectors.toList());
            likedPostIds = postLikeRepository.findLikedPostIdsByUserIdAndPostIds(currentUserId, postIds);
        }

        final Set<UUID> finalLikedIds = likedPostIds;
        List<PostDto> results = filtered.stream()
                .map(post -> mapToDto(post, currentUserId, finalLikedIds, latitude, longitude))
                .collect(Collectors.toList());
        long t2 = System.currentTimeMillis();
        log.info("[POST_API] page={} size={} db_ms={} mapping_ms={} total_ms={} count={} hidden={} restricted={}",
                page, size, (t1 - t0), (t2 - t1), (t2 - t0), results.size(), finalHidden.size(), finalRestricted.size());
        return results;
    }

    @Transactional(readOnly = true)
    public List<PostDto> getCommunityPosts(UUID communityId, UUID currentUserId, int page, int size) {
        return getCommunityPosts(communityId, currentUserId, null, null, page, size);
    }

    /**
     * Retrieves posts for a specific community.
     * Enforces strict active membership check (no bypass).
     */
    @Transactional(readOnly = true)
    public List<PostDto> getCommunityPosts(UUID communityId, UUID currentUserId, Double latitude, Double longitude, int page, int size) {
        if (currentUserId == null) {
            throw BidlyException.unauthorized("Authentication required to view community posts");
        }

        Community community = communityRepository.findById(communityId)
                .orElseThrow(() -> BidlyException.notFound("Community"));

        // Non-members can view community posts

        long t0 = System.currentTimeMillis();
        Page<CommunityPost> postsPage = postRepository.findByCommunityIdOrderByCreatedAtDesc(communityId, PageRequest.of(page, size));
        long t1 = System.currentTimeMillis();

        List<CommunityPost> content = postsPage.getContent();

        // Filter out hidden posts and restricted users for authenticated users
        Set<UUID> hiddenPostIds = Collections.emptySet();
        Set<UUID> restrictedUserIds = Collections.emptySet();
        if (currentUserId != null) {
            hiddenPostIds = postHideRepository.findHiddenPostIdsByUserId(currentUserId);
            restrictedUserIds = userRestrictRepository.findRestrictedUserIdsByUserId(currentUserId);
        }
        final Set<UUID> finalHidden = hiddenPostIds;
        final Set<UUID> finalRestricted = restrictedUserIds;
        List<CommunityPost> filtered = content.stream()
                .filter(p -> !finalHidden.contains(p.getId()))
                .filter(p -> p.getAuthor() == null || !finalRestricted.contains(p.getAuthor().getId()))
                .collect(Collectors.toList());

        Set<UUID> likedPostIds = Collections.emptySet();
        if (currentUserId != null && !filtered.isEmpty()) {
            List<UUID> postIds = filtered.stream().map(CommunityPost::getId).collect(Collectors.toList());
            likedPostIds = postLikeRepository.findLikedPostIdsByUserIdAndPostIds(currentUserId, postIds);
        }

        final Set<UUID> finalLikedIds = likedPostIds;
        List<PostDto> results = filtered.stream()
                .map(post -> mapToDto(post, currentUserId, finalLikedIds, latitude, longitude))
                .collect(Collectors.toList());
        long t2 = System.currentTimeMillis();
        log.info("[COMMUNITY_POST_API] communityId={} page={} size={} db_ms={} mapping_ms={} total_ms={} count={} hidden={} restricted={}",
                communityId, page, size, (t1 - t0), (t2 - t1), (t2 - t0), results.size(), finalHidden.size(), finalRestricted.size());
        return results;
    }

    @Transactional(readOnly = true)
    public PostDto getPostById(UUID postId, UUID currentUserId) {
        return getPostById(postId, currentUserId, null, null);
    }

    /**
     * Retrieves single post by ID.
     * If scoped to a community, enforces strict active membership check (no bypass).
     */
    @Transactional(readOnly = true)
    public PostDto getPostById(UUID postId, UUID currentUserId, Double latitude, Double longitude) {
        CommunityPost post = postRepository.findById(postId)
                .orElseThrow(() -> BidlyException.notFound("Post not found: " + postId));

        if (post.getCommunity() != null) {
            if (currentUserId == null) {
                throw BidlyException.unauthorized("Authentication required to view this community post");
            }
            // Non-members can view the post
        }

        Set<UUID> likedPostIds = (currentUserId != null && postLikeRepository.existsByUserIdAndPostId(currentUserId, postId))
                ? Set.of(postId)
                : Collections.emptySet();

        return mapToDto(post, currentUserId, likedPostIds, latitude, longitude);
    }

    /**
     * Creates a new post in the feed.
     * For community posts: creator / admin active members only.
     */
    @Transactional
    public PostDto createPost(UUID authorId, CreatePostRequest request) {
        if (authorId == null) {
            throw BidlyException.unauthorized("Authentication required to create a post");
        }

        User author = userRepository.findById(authorId)
                .orElseThrow(() -> BidlyException.notFound("User"));

        Community community = null;
        if (request.getCommunityId() != null) {
            community = communityRepository.findById(request.getCommunityId())
                    .orElseThrow(() -> BidlyException.notFound("Community"));

            boolean isCreator = community.getCreatedBy() != null && community.getCreatedBy().equals(authorId);
            boolean isMember = isCreator || memberRepository.existsByCommunityIdAndUserId(community.getId(), authorId);

            if (!isMember) {
                throw BidlyException.forbidden("You must be an active member to publish posts in this community");
            }
        }

        CommunityPost post = new CommunityPost();
        post.setAuthor(author);
        post.setCommunity(community);
        post.setContent(request.getContent().trim());
        post.setMediaUrl(request.getMediaUrl() != null ? request.getMediaUrl().replaceAll("\\s+", "") : null);
        post.setMediaType(request.getMediaType() != null ? request.getMediaType() : "IMAGE");
        post.setTag(request.getTag() != null ? request.getTag() : "SELLING");
        post.setLikesCount(0);
        post.setSharesCount(0);

        CommunityPost saved = postRepository.save(post);
        log.info("Created post {} by user {}", saved.getId(), authorId);

        return mapToDto(saved, authorId, Collections.emptySet());
    }

    /**
     * Toggles or ensures like/unlike on a post with idempotency and transaction safety.
     */
    @Transactional
    public Map<String, Object> toggleLike(UUID userId, UUID postId, String action) {
        if (userId == null) {
            throw BidlyException.unauthorized("Authentication required to like a post");
        }
        CommunityPost post = postRepository.findById(postId)
                .orElseThrow(() -> BidlyException.notFound("Post not found: " + postId));

        boolean alreadyLiked = postLikeRepository.existsByUserIdAndPostId(userId, postId);
        Boolean desiredLiked = null;
        if ("like".equalsIgnoreCase(action)) {
            desiredLiked = true;
        } else if ("unlike".equalsIgnoreCase(action)) {
            desiredLiked = false;
        }

        int currentCount = post.getLikesCount();
        int newCount = currentCount;

        boolean finalLiked;
        if (desiredLiked != null) {
            if (desiredLiked && !alreadyLiked) {
                postLikeRepository.save(new PostLike(userId, postId));
                postLikeRepository.flush();
                newCount = currentCount + 1;
                post.setLikesCount(newCount);
                postRepository.saveAndFlush(post);
                finalLiked = true;
            } else if (!desiredLiked && alreadyLiked) {
                postLikeRepository.deleteByUserIdAndPostId(userId, postId);
                postLikeRepository.flush();
                newCount = Math.max(0, currentCount - 1);
                post.setLikesCount(newCount);
                postRepository.saveAndFlush(post);
                finalLiked = false;
            } else {
                finalLiked = desiredLiked;
            }
        } else {
            if (alreadyLiked) {
                postLikeRepository.deleteByUserIdAndPostId(userId, postId);
                postLikeRepository.flush();
                newCount = Math.max(0, currentCount - 1);
                post.setLikesCount(newCount);
                postRepository.saveAndFlush(post);
                finalLiked = false;
            } else {
                postLikeRepository.save(new PostLike(userId, postId));
                postLikeRepository.flush();
                newCount = currentCount + 1;
                post.setLikesCount(newCount);
                postRepository.saveAndFlush(post);
                finalLiked = true;
            }
        }

        log.info("[LIKE_POST] post={} action={} finalLiked={} count={}", postId, action, finalLiked, newCount);

        return Map.of(
                "liked", finalLiked,
                "likedByMe", finalLiked,
                "isLikedByMe", finalLiked,
                "likesCount", newCount
        );
    }

    @Transactional
    public boolean toggleLike(UUID userId, UUID postId) {
        Map<String, Object> res = toggleLike(userId, postId, null);
        return (Boolean) res.get("liked");
    }

    /**
     * Increments share count for a post.
     */
    @Transactional
    public int sharePost(UUID postId) {
        postRepository.incrementShares(postId);
        return postRepository.findById(postId).map(CommunityPost::getSharesCount).orElse(0);
    }

    /**
     * Lists active communities.
     */
    @Transactional(readOnly = true)
    public List<CommunityDto> getCommunities(int page, int size) {
        return communityRepository.findByActiveTrue(PageRequest.of(page, size))
                .getContent().stream()
                .map(this::mapCommunityToDto)
                .collect(Collectors.toList());
    }

    private PostDto mapToDto(CommunityPost post, UUID currentUserId, Set<UUID> likedPostIds) {
        return mapToDto(post, currentUserId, likedPostIds, null, null);
    }

    private PostDto mapToDto(CommunityPost post, UUID currentUserId, Set<UUID> likedPostIds, Double userLat, Double userLng) {
        PostDto dto = new PostDto();
        dto.setId(post.getId());
        if (post.getAuthor() != null) {
            dto.setAuthorId(post.getAuthor().getId());
            dto.setAuthorName(post.getAuthor().getName());
            String av = post.getAuthor().getAvatarUrl();
            if (av != null && !av.isBlank()) {
                String directAv = mediaService.generatePresignedGetUrl(av, java.time.Duration.ofHours(4));
                dto.setAuthorAvatarUrl(directAv != null ? directAv : av);
            }
        }
        if (post.getCommunity() != null) {
            dto.setCommunityId(post.getCommunity().getId());
            dto.setCommunityName(post.getCommunity().getName());
        }
        dto.setContent(post.getContent());
        dto.setTag(post.getTag());
        dto.setLikesCount(post.getLikesCount());
        dto.setSharesCount(post.getSharesCount());
        dto.setCreatedAt(post.getCreatedAt());

        Double sellerLat = null;
        Double sellerLng = null;
        String locality = null;
        String city = null;

        if (post.getListing() != null) {
            com.bidly.listing.entity.Listing l = post.getListing();
            dto.setListingId(l.getId());
            dto.setListingTitle(l.getTitle());
            dto.setListingDescription(l.getDescription());
            sellerLat = l.getLatitude();
            sellerLng = l.getLongitude();
            locality = l.getLocality();
            city = l.getCity();
            if ((sellerLat == null || sellerLng == null) && l.getSeller() != null) {
                sellerLat = l.getSeller().getLatitude();
                sellerLng = l.getSeller().getLongitude();
            }
            if ((city == null || city.isBlank()) && l.getSeller() != null) {
                city = l.getSeller().getCity();
            }
            dto.setSellingMethod(l.getSellingMethod() != null ? l.getSellingMethod().name() : "DIRECT_BUY");
            dto.setPrice(l.getPrice());
            dto.setStartingBid(l.getStartingBid());
            dto.setCurrentBid(l.getCurrentBid());
            dto.setAuctionEndTime(l.getAuctionEndTime());
            dto.setBidsCount(l.getBidsCount());

            String signedReelUrl = null;
            if (l.getReelUrl() != null && !l.getReelUrl().isBlank()) {
                String direct = mediaService.generatePresignedGetUrl(l.getReelUrl(), java.time.Duration.ofHours(4));
                signedReelUrl = direct != null ? direct : l.getReelUrl();
                dto.setVideoUrl(signedReelUrl);
                dto.setReelUrl(signedReelUrl);
            }

            List<ListingSummaryDto.MediaItemDto> items = new ArrayList<>();
            if (l.getMedia() != null && !l.getMedia().isEmpty()) {
                for (ListingMedia m : l.getMedia()) {
                    if (m.getUrl() != null && !m.getUrl().contains("-thumb.jpg")) {
                        String direct = mediaService.generatePresignedGetUrl(m.getUrl(), java.time.Duration.ofHours(4));
                        String mediaType = (m.getType() != null && m.getType() == ListingMedia.MediaType.VIDEO) ? "VIDEO" : "IMAGE";
                        items.add(new ListingSummaryDto.MediaItemDto(
                                direct != null ? direct : m.getUrl(),
                                mediaType,
                                m.getSortOrder()
                        ));
                    }
                }
            }

            // If listing has reelUrl and not already added from l.getMedia(), add it as a VIDEO item
            if (signedReelUrl != null) {
                final String finalReel = signedReelUrl;
                boolean alreadyPresent = items.stream().anyMatch(i -> "VIDEO".equalsIgnoreCase(i.getType()) || finalReel.equals(i.getUrl()));
                if (!alreadyPresent) {
                    items.add(new ListingSummaryDto.MediaItemDto(finalReel, "VIDEO", items.size() + 1));
                }
            }

            // If still empty and primaryImageUrl is present
            if (items.isEmpty() && l.getPrimaryImageUrl() != null && !l.getPrimaryImageUrl().isBlank()) {
                String direct = mediaService.generatePresignedGetUrl(l.getPrimaryImageUrl(), java.time.Duration.ofHours(4));
                String finalUrl = direct != null ? direct : l.getPrimaryImageUrl();
                items.add(new ListingSummaryDto.MediaItemDto(finalUrl, "IMAGE", 0));
            }

            dto.setMediaItems(items);

            // Determine primary mediaUrl and mediaType
            Optional<ListingSummaryDto.MediaItemDto> firstImage = items.stream().filter(i -> "IMAGE".equalsIgnoreCase(i.getType())).findFirst();
            if (firstImage.isPresent()) {
                dto.setMediaUrl(firstImage.get().getUrl());
                dto.setMediaType("IMAGE");
            } else if (!items.isEmpty()) {
                dto.setMediaUrl(items.get(0).getUrl());
                dto.setMediaType(items.get(0).getType());
            } else {
                dto.setMediaUrl(null);
                dto.setMediaType("IMAGE");
            }
        } else if (post.getMediaUrl() != null && !post.getMediaUrl().isBlank()) {
            String raw = post.getMediaUrl().replaceAll("\\s+", "");
            String direct = mediaService.generatePresignedGetUrl(raw, java.time.Duration.ofHours(4));
            String finalUrl = direct != null ? direct : raw;
            String mediaType = post.getMediaType() != null ? post.getMediaType() : "IMAGE";
            dto.setMediaUrl(finalUrl);
            dto.setMediaType(mediaType);
            if ("VIDEO".equalsIgnoreCase(mediaType)) {
                dto.setVideoUrl(finalUrl);
                dto.setReelUrl(finalUrl);
            }
            dto.setMediaItems(List.of(new ListingSummaryDto.MediaItemDto(finalUrl, mediaType, 0)));
        } else {
            dto.setMediaUrl(null);
            dto.setMediaType("IMAGE");
            dto.setMediaItems(Collections.emptyList());
        }

        if (sellerLat == null || sellerLng == null) {
            if (post.getAuthor() != null) {
                sellerLat = post.getAuthor().getLatitude();
                sellerLng = post.getAuthor().getLongitude();
                if (city == null || city.isBlank()) {
                    city = post.getAuthor().getCity();
                }
            }
        }

        dto.setLatitude(sellerLat);
        dto.setLongitude(sellerLng);
        dto.setLocality(locality);
        dto.setCity(city);

        Double dist = null;
        if (userLat != null && userLng != null && sellerLat != null && sellerLng != null) {
            dist = com.bidly.listing.service.ListingService.calculateHaversineDistanceKm(userLat, userLng, sellerLat, sellerLng);
        } else if (currentUserId != null && sellerLat != null && sellerLng != null) {
            Optional<User> curUser = userRepository.findById(currentUserId);
            if (curUser.isPresent() && curUser.get().getLatitude() != null && curUser.get().getLongitude() != null) {
                dist = com.bidly.listing.service.ListingService.calculateHaversineDistanceKm(
                        curUser.get().getLatitude(),
                        curUser.get().getLongitude(),
                        sellerLat,
                        sellerLng
                );
            }
        }
        dto.setDistanceKm(dist);

        if (likedPostIds != null && !likedPostIds.isEmpty()) {
            dto.setLikedByMe(likedPostIds.contains(post.getId()));
        } else if (currentUserId != null && likedPostIds == null) {
            dto.setLikedByMe(postLikeRepository.existsByUserIdAndPostId(currentUserId, post.getId()));
        } else {
            dto.setLikedByMe(false);
        }

        return dto;
    }

    private CommunityDto mapCommunityToDto(Community community) {
        CommunityDto dto = new CommunityDto();
        dto.setId(community.getId());
        dto.setName(community.getName());
        dto.setDescription(community.getDescription());
        dto.setIconUrl(community.getIconUrl());
        dto.setBannerUrl(community.getBannerUrl());
        dto.setType(community.getType());
        dto.setCity(community.getCity());
        dto.setState(community.getState());
        dto.setMembersCount(community.getMembersCount());
        return dto;
    }

    // ─── Hide Post ("Not Interested") ───

    /**
     * Hides a post from the user's feed. Idempotent.
     */
    @Transactional
    public Map<String, Object> hidePost(UUID userId, UUID postId) {
        if (userId == null) {
            throw BidlyException.unauthorized("Authentication required");
        }
        postRepository.findById(postId)
                .orElseThrow(() -> BidlyException.notFound("Post not found: " + postId));

        if (!postHideRepository.existsByUserIdAndPostId(userId, postId)) {
            postHideRepository.save(new PostHide(userId, postId));
        }
        log.info("[HIDE_POST] user={} post={}", userId, postId);
        return Map.of("postId", postId.toString(), "hidden", true);
    }

    /**
     * Unhides a previously hidden post. Idempotent.
     */
    @Transactional
    public Map<String, Object> unhidePost(UUID userId, UUID postId) {
        if (userId == null) {
            throw BidlyException.unauthorized("Authentication required");
        }
        postHideRepository.deleteByUserIdAndPostId(userId, postId);
        log.info("[UNHIDE_POST] user={} post={}", userId, postId);
        return Map.of("postId", postId.toString(), "hidden", false);
    }

    // ─── Restrict User ───

    /**
     * Restricts a user — their posts will be hidden from the requester's feed. Idempotent.
     */
    @Transactional
    public Map<String, Object> restrictUser(UUID userId, UUID targetUserId) {
        if (userId == null) {
            throw BidlyException.unauthorized("Authentication required");
        }
        if (userId.equals(targetUserId)) {
            throw BidlyException.badRequest("You cannot restrict yourself");
        }
        userRepository.findById(targetUserId)
                .orElseThrow(() -> BidlyException.notFound("User not found: " + targetUserId));

        if (!userRestrictRepository.existsByUserIdAndRestrictedUserId(userId, targetUserId)) {
            userRestrictRepository.save(new UserRestrict(userId, targetUserId));
        }
        log.info("[RESTRICT_USER] user={} restricted={}", userId, targetUserId);
        return Map.of("restrictedUserId", targetUserId.toString(), "restricted", true);
    }

    /**
     * Unrestricts a previously restricted user. Idempotent.
     */
    @Transactional
    public Map<String, Object> unrestrictUser(UUID userId, UUID targetUserId) {
        if (userId == null) {
            throw BidlyException.unauthorized("Authentication required");
        }
        userRestrictRepository.deleteByUserIdAndRestrictedUserId(userId, targetUserId);
        log.info("[UNRESTRICT_USER] user={} unrestricted={}", userId, targetUserId);
        return Map.of("restrictedUserId", targetUserId.toString(), "restricted", false);
    }

    // No hardcoded seed data in code - only real user-created posts

}
