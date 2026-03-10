package com.vacanza.backend.service;

import com.vacanza.backend.dto.response.UserAuthenticationDTO;
import com.vacanza.backend.entity.LoginHistory;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.repo.UserInfoRepository;
import com.vacanza.backend.repo.UserLoginHistoryRepository;
import com.vacanza.backend.security.CurrentUserProvider;

import jakarta.servlet.http.HttpServletRequest;
import lombok.AllArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

/**
 * Authentication service:
 * - /auth/me: resolves current user, returns identity + role + verified +
 * profileCompleted
 * - /auth/logout: logs logout event, clears security context
 * - writes login_history entries (server-side)
 */
@Service
@AllArgsConstructor
public class AuthService {

    private final CurrentUserProvider currentUserProvider;
    private final UserInfoRepository userInfoRepository;
    private final UserLoginHistoryRepository loginHistoryRepository;

    @Transactional
    public UserAuthenticationDTO getMe(HttpServletRequest request) {
        User user = currentUserProvider.getCurrentUserEntity();

        boolean profileCompleted = userInfoRepository.existsByUser(user);

        // Filter sets these attributes when token is present+verified.
        boolean emailVerified = Boolean.TRUE.equals(request.getAttribute("firebaseEmailVerified"));

        // Log login history (server-side). Minimal: each /auth/me call logs one record.
        loginHistoryRepository.save(
                LoginHistory.builder()
                        .user(user)
                        .loginProvider("firebase")
                        .loginTime(Instant.now())
                        .ipAddress(resolveClientIp(request))
                        .build());

        return UserAuthenticationDTO.builder()
                .userId(user.getUserId())
                .firebaseUid(user.getFirebaseUid())
                .email(user.getEmail())
                .role(user.getRole().name())
                .verified(emailVerified)
                .profileCompleted(profileCompleted)
                .build();
    }

    /**
     * Logout: logs the event and clears SecurityContext.
     * Token invalidation is handled by Firebase on the client side.
     */
    @Transactional
    public void logout(HttpServletRequest request) {
        User user = currentUserProvider.getCurrentUserEntity();

        loginHistoryRepository.save(
                LoginHistory.builder()
                        .user(user)
                        .loginProvider("firebase-logout")
                        .loginTime(Instant.now())
                        .ipAddress(resolveClientIp(request))
                        .build());

        SecurityContextHolder.clearContext();
    }

    /**
     * Tries to resolve client IP behind proxy/load balancer too.
     */
    private String resolveClientIp(HttpServletRequest request) {
        String xff = request.getHeader("X-Forwarded-For");
        if (xff != null && !xff.isBlank()) {
            // Take first IP in list
            return xff.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
