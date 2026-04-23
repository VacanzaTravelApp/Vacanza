package com.vacanza.backend.repo;

import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AiRouteRepository extends JpaRepository<AiRoute, UUID> {

    List<AiRoute> findByUserOrderByGeneratedAtDesc(User user);

    Optional<AiRoute> findByRouteIdAndUser(UUID routeId, User user);

    List<AiRoute> findByUserAndConversationIdOrderByGeneratedAtAsc(User user, UUID conversationId);

    /** Latest version of a route chain (highest version number). */
    @Query("SELECT r FROM AiRoute r WHERE r.user = :user AND r.conversationId = :conversationId ORDER BY r.version DESC")
    List<AiRoute> findByUserAndConversationIdOrderByVersionDesc(
            @Param("user") User user,
            @Param("conversationId") UUID conversationId);

    /**
     * All versions in the chain rooted at {@code rootRouteId}.
     * Version 1 row has parentRouteId = null; we query by conversationId + routeId ancestry.
     * Simple approach: fetch all rows that share the same conversationId, caller selects the chain.
     */
    @Query("SELECT r FROM AiRoute r WHERE r.parentRouteId = :parentRouteId ORDER BY r.version ASC")
    List<AiRoute> findVersionsByParentRouteId(@Param("parentRouteId") UUID parentRouteId);
}
