package com.vacanza.backend.repo;

import com.vacanza.backend.entity.User;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, UUID> {

    // login/register kontrolu
    Optional<User> findByEmail(String email);

    Optional<User> findByFirebaseUid(String firebaseUid);

    boolean existsByEmail(String email);

    boolean existsByFirebaseUid(String firebaseUid);
}
