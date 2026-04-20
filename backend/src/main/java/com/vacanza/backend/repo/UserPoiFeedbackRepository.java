package com.vacanza.backend.repo;

import com.vacanza.backend.entity.UserPoiFeedback;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserPoiFeedbackRepository extends JpaRepository<UserPoiFeedback, UUID> {

    Optional<UserPoiFeedback> findByUser_UserIdAndPoiKey(UUID userId, String poiKey);

    List<UserPoiFeedback> findByUser_UserId(UUID userId);

    List<UserPoiFeedback> findByUser_UserIdAndScoreGreaterThan(UUID userId, double score);
}
