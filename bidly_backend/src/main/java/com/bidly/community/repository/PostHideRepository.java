package com.bidly.community.repository;

import com.bidly.community.entity.PostHide;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;
import java.util.UUID;

@Repository
public interface PostHideRepository extends JpaRepository<PostHide, PostHide.PostHideId> {

    boolean existsByUserIdAndPostId(UUID userId, UUID postId);

    @Transactional
    void deleteByUserIdAndPostId(UUID userId, UUID postId);

    /**
     * Returns the set of post IDs that this user has hidden.
     */
    @Query("SELECT ph.postId FROM PostHide ph WHERE ph.userId = :userId")
    Set<UUID> findHiddenPostIdsByUserId(UUID userId);
}
