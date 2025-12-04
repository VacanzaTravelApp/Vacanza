package com.vacanza.backend.repo;

import com.vacanza.backend.entity.LoginHistory;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LoginHistoryRepository extends JpaRepository<LoginHistory, UUID> {

    //login history for an user
    List<LoginHistory> findByUserUserId(UUID userId);
}
