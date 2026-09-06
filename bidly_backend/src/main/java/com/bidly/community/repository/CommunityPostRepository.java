package com.bidly.community.repository;

import com.bidly.community.entity.CommunityPost;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Repository
public interface CommunityPostRepository extends JpaRepository<CommunityPost, UUID> {

    @EntityGraph(attributePaths = {"author", "community", "listing"})
    Page<CommunityPost> findAllByOrderByCreatedAtDesc(Pageable pageable);

    @EntityGraph(attributePaths = {"author", "community", "listing"})
    @Query("SELECT p FROM CommunityPost p LEFT JOIN p.listing l " +
           "WHERE p.community IS NULL " +
           "AND (l IS NULL OR (l.status = 'ACTIVE' " +
           "AND (l.sellingMethod <> 'AUCTION' OR l.auctionEndTime IS NULL OR l.auctionEndTime > CURRENT_TIMESTAMP) " +
           "AND (l.reelUrl IS NULL OR TRIM(l.reelUrl) = '' " +
           "OR EXISTS (SELECT lm FROM ListingMedia lm WHERE lm.listing = l AND lm.type = com.bidly.listing.entity.ListingMedia.MediaType.IMAGE AND lm.url NOT LIKE '%-thumb.jpg%')))) " +
           "ORDER BY p.createdAt DESC")
    Page<CommunityPost> findByCommunityIsNullOrderByCreatedAtDesc(Pageable pageable);

    @EntityGraph(attributePaths = {"author", "community", "listing"})
    @Query("SELECT p FROM CommunityPost p LEFT JOIN p.listing l " +
           "WHERE p.community.id = :communityId " +
           "AND (l IS NULL OR (l.status = 'ACTIVE' " +
           "AND (l.sellingMethod <> 'AUCTION' OR l.auctionEndTime IS NULL OR l.auctionEndTime > CURRENT_TIMESTAMP) " +
           "AND (l.reelUrl IS NULL OR TRIM(l.reelUrl) = '' " +
           "OR EXISTS (SELECT lm FROM ListingMedia lm WHERE lm.listing = l AND lm.type = com.bidly.listing.entity.ListingMedia.MediaType.IMAGE AND lm.url NOT LIKE '%-thumb.jpg%')))) " +
           "ORDER BY p.createdAt DESC")
    Page<CommunityPost> findByCommunityIdOrderByCreatedAtDesc(UUID communityId, Pageable pageable);

    @Modifying
    @Transactional
    @Query("UPDATE CommunityPost p SET p.likesCount = p.likesCount + 1 WHERE p.id = :id")
    void incrementLikes(UUID id);

    @Modifying
    @Transactional
    @Query("UPDATE CommunityPost p SET p.likesCount = CASE WHEN p.likesCount > 0 THEN p.likesCount - 1 ELSE 0 END WHERE p.id = :id")
    void decrementLikes(UUID id);

    @Modifying
    @Transactional
    @Query("UPDATE CommunityPost p SET p.sharesCount = p.sharesCount + 1 WHERE p.id = :id")
    void incrementShares(UUID id);
}
