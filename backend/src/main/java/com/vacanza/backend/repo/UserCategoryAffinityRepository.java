package com.vacanza.backend.repo;

import com.vacanza.backend.entity.UserCategoryAffinity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserCategoryAffinityRepository extends JpaRepository<UserCategoryAffinity, UUID> {

    Optional<UserCategoryAffinity> findByUser_UserIdAndCategoryKey(UUID userId, String categoryKey);

    List<UserCategoryAffinity> findByUser_UserId(UUID userId);
}
