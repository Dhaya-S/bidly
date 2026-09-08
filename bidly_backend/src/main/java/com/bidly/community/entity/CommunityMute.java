package com.bidly.community.entity;

import jakarta.persistence.*;
import java.io.Serializable;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Tracks which communities a user has muted notifications for.
 */
@Entity
@Table(name = "community_mutes")
@IdClass(CommunityMute.CommunityMuteId.class)
public class CommunityMute {

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Id
    @Column(name = "community_id")
    private UUID communityId;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    public CommunityMute() {}

    public CommunityMute(UUID userId, UUID communityId) {
        this.userId = userId;
        this.communityId = communityId;
        this.createdAt = Instant.now();
    }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public UUID getCommunityId() { return communityId; }
    public void setCommunityId(UUID communityId) { this.communityId = communityId; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public static class CommunityMuteId implements Serializable {
        private UUID userId;
        private UUID communityId;

        public CommunityMuteId() {}

        public CommunityMuteId(UUID userId, UUID communityId) {
            this.userId = userId;
            this.communityId = communityId;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            CommunityMuteId that = (CommunityMuteId) o;
            return Objects.equals(userId, that.userId) && Objects.equals(communityId, that.communityId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(userId, communityId);
        }
    }
}
