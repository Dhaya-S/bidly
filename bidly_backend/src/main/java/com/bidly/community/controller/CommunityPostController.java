package com.bidly.community.controller;

import com.bidly.common.dto.ApiResponse;
import com.bidly.community.dto.CommunityDto;
import com.bidly.community.dto.CreatePostRequest;
import com.bidly.community.dto.PostDto;
import com.bidly.community.service.CommunityPostService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/posts")
public class CommunityPostController {

    private final CommunityPostService postService;

    public CommunityPostController(CommunityPostService postService) {
        this.postService = postService;
    }

    /**
     * GET /api/posts — Get global feed of posts
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<PostDto>>> getFeed(
            @AuthenticationPrincipal UUID currentUserId,
            @RequestParam(required = false) Double latitude,
            @RequestParam(required = false) Double longitude,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        List<PostDto> feed = postService.getFeed(currentUserId, latitude, longitude, page, size);
        return ResponseEntity.ok(ApiResponse.success(feed));
    }

    /**
     * GET /api/posts/community/{communityId}
     */
    @GetMapping("/community/{communityId}")
    public ResponseEntity<ApiResponse<List<PostDto>>> getCommunityPosts(
            @PathVariable UUID communityId,
            @AuthenticationPrincipal UUID currentUserId,
            @RequestParam(required = false) Double latitude,
            @RequestParam(required = false) Double longitude,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        List<PostDto> posts = postService.getCommunityPosts(communityId, currentUserId, latitude, longitude, page, size);
        return ResponseEntity.ok(ApiResponse.success(posts));
    }

    /**
     * GET /api/posts/{id} — Get post by ID (membership enforced if community post)
     */
    @GetMapping("/{id:[a-fA-F0-9\\-]{36}}")
    public ResponseEntity<ApiResponse<PostDto>> getPost(
            @PathVariable UUID id,
            @AuthenticationPrincipal UUID currentUserId,
            @RequestParam(required = false) Double latitude,
            @RequestParam(required = false) Double longitude) {
        PostDto post = postService.getPostById(id, currentUserId, latitude, longitude);
        return ResponseEntity.ok(ApiResponse.success(post));
    }

    /**
     * POST /api/posts — Create a new post
     */
    @PostMapping
    public ResponseEntity<ApiResponse<PostDto>> createPost(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody CreatePostRequest request) {
        PostDto postDto = postService.createPost(userId, request);
        return ResponseEntity.ok(ApiResponse.success("Post created", postDto));
    }

    /**
     * POST /api/posts/{id}/like — Toggle or ensure like/unlike on a post
     */
    @PostMapping("/{id:[a-fA-F0-9\\-]{36}}/like")
    public ResponseEntity<ApiResponse<Map<String, Object>>> toggleLike(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID id,
            @RequestParam(required = false) String action) {
        Map<String, Object> result = postService.toggleLike(userId, id, action);
        return ResponseEntity.ok(ApiResponse.success(result));
    }

    /**
     * POST /api/posts/{id}/share — Increment share count
     */
    @PostMapping("/{id:[a-fA-F0-9\\-]{36}}/share")
    public ResponseEntity<ApiResponse<Map<String, Object>>> sharePost(@PathVariable UUID id) {
        int count = postService.sharePost(id);
        return ResponseEntity.ok(ApiResponse.success(Map.of("sharesCount", count)));
    }

    /**
     * GET /api/posts/communities — List active communities
     */
    @GetMapping("/communities")
    public ResponseEntity<ApiResponse<List<CommunityDto>>> getCommunities(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        List<CommunityDto> communities = postService.getCommunities(page, size);
        return ResponseEntity.ok(ApiResponse.success(communities));
    }

    /**
     * POST /api/posts/{id}/hide — Hide a post ("Not Interested")
     */
    @PostMapping("/{id:[a-fA-F0-9\\-]{36}}/hide")
    public ResponseEntity<ApiResponse<Map<String, Object>>> hidePost(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID id) {
        Map<String, Object> result = postService.hidePost(userId, id);
        return ResponseEntity.ok(ApiResponse.success("Post hidden", result));
    }

    /**
     * DELETE /api/posts/{id}/hide — Unhide a previously hidden post
     */
    @DeleteMapping("/{id:[a-fA-F0-9\\-]{36}}/hide")
    public ResponseEntity<ApiResponse<Map<String, Object>>> unhidePost(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID id) {
        Map<String, Object> result = postService.unhidePost(userId, id);
        return ResponseEntity.ok(ApiResponse.success("Post unhidden", result));
    }

    /**
     * POST /api/posts/restrict/{targetUserId} — Restrict a user (hide their posts from feed)
     */
    @PostMapping("/restrict/{targetUserId:[a-fA-F0-9\\-]{36}}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> restrictUser(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID targetUserId) {
        Map<String, Object> result = postService.restrictUser(userId, targetUserId);
        return ResponseEntity.ok(ApiResponse.success("User restricted", result));
    }

    /**
     * DELETE /api/posts/restrict/{targetUserId} — Unrestrict a user
     */
    @DeleteMapping("/restrict/{targetUserId:[a-fA-F0-9\\-]{36}}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> unrestrictUser(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID targetUserId) {
        Map<String, Object> result = postService.unrestrictUser(userId, targetUserId);
        return ResponseEntity.ok(ApiResponse.success("User unrestricted", result));
    }
}
