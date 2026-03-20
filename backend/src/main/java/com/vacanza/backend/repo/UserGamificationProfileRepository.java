package com.vacanza.backend.repo;

import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserGamificationProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserGamificationProfileRepository extends JpaRepository<UserGamificationProfile, UUID> {

    Optional<UserGamificationProfile> findByUser(User user);
}
