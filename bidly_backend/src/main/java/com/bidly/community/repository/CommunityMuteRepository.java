package com.bidly.community.repository;

import com.bidly.community.entity.CommunityMute;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;
import java.util.UUID;

@Repository
public interface CommunityMuteRepository extends JpaRepository<CommunityMute, CommunityMute.CommunityMuteId> {

    boolean existsByUserIdAndCommunityId(UUID userId, UUID communityId);

    @Transactional
    void deleteByUserIdAndCommunityId(UUID userId, UUID communityId);

    /**
     * Returns the set of community IDs that this user has muted.
     */
    @Query("SELECT cm.communityId FROM CommunityMute cm WHERE cm.userId = :userId")
    Set<UUID> findMutedCommunityIdsByUserId(UUID userId);
}
