package com.vacanza.backend.security;

import com.vacanza.backend.entity.User;
import com.vacanza.backend.repo.UserRepository;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

/**
    to resolve the currently authenticated user.
    principal is set by FirebaseTokenFilter as firebaseUid.
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
            throw new IllegalStateException("No authenticated user in SecurityContext");
        }
        return String.valueOf(auth.getPrincipal());
    }

    public User getCurrentUserEntity() {
        String uid = getFirebaseUid();
        return userRepository.findByFirebaseUid(uid)
                .orElseThrow(() -> new IllegalStateException("Authenticated user not found in database"));
    }
}
