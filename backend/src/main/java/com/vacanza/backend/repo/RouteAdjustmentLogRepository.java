package com.vacanza.backend.repo;

import com.vacanza.backend.entity.RouteAdjustmentLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RouteAdjustmentLogRepository extends JpaRepository<RouteAdjustmentLog, UUID> {

    Optional<RouteAdjustmentLog> findByIdempotencyKey(String idempotencyKey);

    List<RouteAdjustmentLog> findByRouteIdOrderByCreatedAtDesc(UUID routeId);

    /** Most-recent completed adjustment for a route (used to retrieve latest result_route_id). */
    @Query("SELECT r FROM RouteAdjustmentLog r WHERE r.routeId = :routeId AND r.status = 'COMPLETED' ORDER BY r.completedAt DESC")
    List<RouteAdjustmentLog> findCompletedByRouteIdOrderByCompletedAtDesc(@Param("routeId") UUID routeId);
}
