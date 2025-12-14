package com.vacanza.backend.security;

import com.vacanza.backend.entity.User;
import com.vacanza.backend.repo.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

/**
 * Resolves current user from SecurityContext.
 * principal is set by FirebaseTokenFilter as firebaseUid.
 */
@Component
public class CurrentUserProvider {

    private final UserRepository userRepository;

    public CurrentUserProvider(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public String getFirebaseUid() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        if (auth == null || !auth.isAuthenticated() || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Missing Authorization Bearer token");
        }

        String principal = String.valueOf(auth.getPrincipal());
        if (principal.isBlank() || "anonymousUser".equalsIgnoreCase(principal)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Missing Authorization Bearer token");
        }

        return principal;
    }

    public User getCurrentUserEntity() {
        String uid = getFirebaseUid();
        return userRepository.findByFirebaseUid(uid)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Authenticated user not found in database"
                ));
    }
}