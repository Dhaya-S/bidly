package com.bidly.community.repository;

import com.bidly.community.entity.UserRestrict;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;
import java.util.UUID;

@Repository
public interface UserRestrictRepository extends JpaRepository<UserRestrict, UserRestrict.UserRestrictId> {

    boolean existsByUserIdAndRestrictedUserId(UUID userId, UUID restrictedUserId);

    @Transactional
    void deleteByUserIdAndRestrictedUserId(UUID userId, UUID restrictedUserId);

    /**
     * Returns the set of user IDs that this user has restricted.
     */
    @Query("SELECT ur.restrictedUserId FROM UserRestrict ur WHERE ur.userId = :userId")
    Set<UUID> findRestrictedUserIdsByUserId(UUID userId);
}
