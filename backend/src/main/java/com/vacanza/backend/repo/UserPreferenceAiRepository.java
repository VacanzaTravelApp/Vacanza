package com.vacanza.backend.repo;

import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserPreferenceAi;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserPreferenceAiRepository extends JpaRepository<UserPreferenceAi, UUID> {

    List<UserPreferenceAi> findByUser(User user);

    Optional<UserPreferenceAi> findByUserAndPreferenceKey(User user, String preferenceKey);

    List<UserPreferenceAi> findByUserAndSource(User user, String source);

    List<UserPreferenceAi> findByUserAndConfidenceGreaterThanEqual(User user, Double minConfidence);

    void deleteByUserAndPreferenceKey(User user, String preferenceKey);
}
