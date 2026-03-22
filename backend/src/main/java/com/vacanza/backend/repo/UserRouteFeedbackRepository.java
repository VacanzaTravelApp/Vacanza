package com.vacanza.backend.repo;

import com.vacanza.backend.entity.UserRouteFeedback;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRouteFeedbackRepository extends JpaRepository<UserRouteFeedback, UUID> {

    Optional<UserRouteFeedback> findByUser_UserIdAndRoute_RouteId(UUID userId, UUID routeId);

    List<UserRouteFeedback> findByUser_UserIdAndRoute_RouteIdIn(UUID userId, Collection<UUID> routeIds);
}
