package com.bidly.community.entity;

import jakarta.persistence.*;
import java.io.Serializable;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Tracks user-level restrictions.
 * When userId restricts restrictedUserId, posts from that user are hidden from their feed.
 */
@Entity
@Table(name = "user_restricts")
@IdClass(UserRestrict.UserRestrictId.class)
public class UserRestrict {

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Id
    @Column(name = "restricted_user_id")
    private UUID restrictedUserId;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    public UserRestrict() {}

    public UserRestrict(UUID userId, UUID restrictedUserId) {
        this.userId = userId;
        this.restrictedUserId = restrictedUserId;
        this.createdAt = Instant.now();
    }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public UUID getRestrictedUserId() { return restrictedUserId; }
    public void setRestrictedUserId(UUID restrictedUserId) { this.restrictedUserId = restrictedUserId; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public static class UserRestrictId implements Serializable {
        private UUID userId;
        private UUID restrictedUserId;

        public UserRestrictId() {}

        public UserRestrictId(UUID userId, UUID restrictedUserId) {
            this.userId = userId;
            this.restrictedUserId = restrictedUserId;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            UserRestrictId that = (UserRestrictId) o;
            return Objects.equals(userId, that.userId) && Objects.equals(restrictedUserId, that.restrictedUserId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(userId, restrictedUserId);
        }
    }
}
