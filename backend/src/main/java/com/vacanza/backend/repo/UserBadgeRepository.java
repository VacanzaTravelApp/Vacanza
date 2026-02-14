package com.vacanza.backend.repo;

import com.vacanza.backend.entity.Badge;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserBadge;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface UserBadgeRepository extends JpaRepository<UserBadge, UUID> {

    List<UserBadge> findAllByUser(User user);

    boolean existsByUserAndBadge(User user, Badge badge);
}
