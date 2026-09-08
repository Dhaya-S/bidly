package com.bidly.community.repository;

import com.bidly.community.entity.PostLike;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

@Repository
public interface PostLikeRepository extends JpaRepository<PostLike, PostLike.PostLikeId> {
    boolean existsByUserIdAndPostId(UUID userId, UUID postId);
    Optional<PostLike> findByUserIdAndPostId(UUID userId, UUID postId);
    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.transaction.annotation.Transactional
    @Query("DELETE FROM PostLike pl WHERE pl.userId = :userId AND pl.postId = :postId")
    void deleteByUserIdAndPostId(@Param("userId") UUID userId, @Param("postId") UUID postId);
    long countByPostId(UUID postId);

    @Query("SELECT pl.postId FROM PostLike pl WHERE pl.userId = :userId AND pl.postId IN :postIds")
    Set<UUID> findLikedPostIdsByUserIdAndPostIds(
            @Param("userId") UUID userId,
            @Param("postIds") Collection<UUID> postIds
    );
}
