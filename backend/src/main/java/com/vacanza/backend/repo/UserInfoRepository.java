package com.vacanza.backend.repo;

import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserInfo;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserInfoRepository extends JpaRepository<UserInfo, UUID> {

    Optional<UserInfo> findByUser(User user);

    boolean existsByUser(User user);
}
