//package com.vacanza.backend.repo;
//
//import com.vacanza.backend.entity.UserSession;
//import java.util.Optional;
//import java.util.UUID;
//import org.springframework.data.jpa.repository.JpaRepository;
//
//public interface UserSessionRepository extends JpaRepository<UserSession, UUID> {
//
//    Optional<UserSession> findBySessionToken(String sessionToken);
//
//    // logout icin
//    void deleteBySessionToken(String sessionToken);
//
//    boolean existsBySessionToken(String sessionToken);
//}
