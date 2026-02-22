package com.vacanza.backend.repo;

import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserInteraction;
import com.vacanza.backend.entity.enums.InteractionType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface UserInteractionRepository extends JpaRepository<UserInteraction, UUID> {

    List<UserInteraction> findByUserOrderByCreatedAtDesc(User user, Pageable pageable);

    List<UserInteraction> findByUserAndInteractionTypeOrderByCreatedAtDesc(
            User user, InteractionType interactionType, Pageable pageable);

    List<UserInteraction> findByUserAndCreatedAtAfterOrderByCreatedAtDesc(
            User user, Instant since, Pageable pageable);
}
