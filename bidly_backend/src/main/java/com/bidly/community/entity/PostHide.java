package com.bidly.community.entity;

import jakarta.persistence.*;
import java.io.Serializable;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Tracks posts a user has marked as "Not Interested".
 * Hidden posts are excluded from their feed in real-time.
 */
@Entity
@Table(name = "post_hides")
@IdClass(PostHide.PostHideId.class)
public class PostHide {

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Id
    @Column(name = "post_id")
    private UUID postId;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    public PostHide() {}

    public PostHide(UUID userId, UUID postId) {
        this.userId = userId;
        this.postId = postId;
        this.createdAt = Instant.now();
    }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public UUID getPostId() { return postId; }
    public void setPostId(UUID postId) { this.postId = postId; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public static class PostHideId implements Serializable {
        private UUID userId;
        private UUID postId;

        public PostHideId() {}

        public PostHideId(UUID userId, UUID postId) {
            this.userId = userId;
            this.postId = postId;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            PostHideId that = (PostHideId) o;
            return Objects.equals(userId, that.userId) && Objects.equals(postId, that.postId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(userId, postId);
        }
    }
}
