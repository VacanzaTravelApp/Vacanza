package com.vacanza.backend.repo;

import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AiRouteRepository extends JpaRepository<AiRoute, UUID> {

    List<AiRoute> findByUserOrderByGeneratedAtDesc(User user);

    Optional<AiRoute> findByRouteIdAndUser(UUID routeId, User user);
}
