package com.vacanza.backend.repo;

import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserPreferences;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserPreferencesRepository extends JpaRepository<UserPreferences, UUID> {

    Optional<UserPreferences> findByUser(User user);

    boolean existsByUser(User user);
}
