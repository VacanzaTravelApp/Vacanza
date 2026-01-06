package com.vacanza.backend.repo;

import com.vacanza.backend.entity.LoginHistory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface UserLoginHistoryRepository extends JpaRepository<LoginHistory, UUID> {

    //login history for an user
    List<LoginHistory> findByUserUserId(UUID userId);
}
