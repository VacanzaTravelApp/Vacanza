package com.vacanza.backend.repo;

import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserInteraction;
import com.vacanza.backend.entity.enums.InteractionType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface UserInteractionRepository extends JpaRepository<UserInteraction, UUID> {

    List<UserInteraction> findByUserOrderByCreatedAtDesc(User user, Pageable pageable);

    List<UserInteraction> findByUserAndInteractionTypeOrderByCreatedAtDesc(
            User user, InteractionType interactionType, Pageable pageable);

    List<UserInteraction> findByUserAndCreatedAtAfterOrderByCreatedAtDesc(
            User user, Instant since, Pageable pageable);

    long countByUser(User user);

    /**
     * Count POI categories per interaction type (POI_VIEW, POI_FAVORITE)
     * by joining with points_of_interest table.
     * Returns rows of [interaction_type (String), category (String), count (Long)].
     */
    @Query(value = """
            SELECT ui.interaction_type, p.category, COUNT(*) as cnt
            FROM user_interactions ui
            JOIN points_of_interest p ON p.poi_id = ui.target_id
            WHERE ui.user_id = :userId
              AND ui.interaction_type IN ('POI_VIEW', 'POI_FAVORITE')
            GROUP BY ui.interaction_type, p.category
            ORDER BY cnt DESC
            """, nativeQuery = true)
    List<Object[]> countPoiCategoriesByUser(@Param("userId") UUID userId);

    /**
     * Count categories from CATEGORY_FILTER interactions
     * by extracting category from metadata jsonb.
     * Returns rows of [category (String), count (Long)].
     */
    @Query(value = """
            SELECT metadata->>'category' as cat, COUNT(*) as cnt
            FROM user_interactions
            WHERE user_id = :userId
              AND interaction_type = 'CATEGORY_FILTER'
              AND metadata->>'category' IS NOT NULL
            GROUP BY cat
            ORDER BY cnt DESC
            """, nativeQuery = true)
    List<Object[]> countFilterCategoriesByUser(@Param("userId") UUID userId);

    /**
     * Count interaction types for a user (to weight different behaviors).
     * Returns rows of [interactionType (String), count (Long)].
     */
    @Query(value = """
            SELECT interaction_type, COUNT(*) as cnt
            FROM user_interactions
            WHERE user_id = :userId
            GROUP BY interaction_type
            ORDER BY cnt DESC
            """, nativeQuery = true)
    List<Object[]> countInteractionTypesByUser(@Param("userId") UUID userId);
}
