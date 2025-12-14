package com.vacanza.backend.security;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.enums.Role;
import com.vacanza.backend.repo.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/**
 * Validates Firebase ID Token sent by frontend:
 * Authorization: Bearer <firebase_id_token>
 * <p>
 * If valid:
 * - sync user to DB (users table)
 * - sets SecurityContext principal = firebaseUid, authority = ROLE_*
 * - sets request attributes: firebaseEmail, firebaseEmailVerified
 * <p>
 * If invalid:
 * - responds 401 Unauthorized
 */
@Component
public class FirebaseTokenFilter extends OncePerRequestFilter {

    private final UserRepository userRepository;

    public FirebaseTokenFilter(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        boolean contextSetByThisFilter = false;

        try {
            String header = request.getHeader(HttpHeaders.AUTHORIZATION);

            // No bearer -> just continue (endpoints that require auth will fail in CurrentUserProvider)
            if (header == null || !header.startsWith("Bearer ")) {
                filterChain.doFilter(request, response);
                return;
            }

            String token = header.substring("Bearer ".length()).trim();

            FirebaseToken decoded = FirebaseAuth.getInstance().verifyIdToken(token);

            String uid = decoded.getUid();
            String email = decoded.getEmail(); // can be null for some providers
            boolean emailVerified = Boolean.TRUE.equals(decoded.isEmailVerified());

            // DB sync: create user if missing
            User user = userRepository.findByFirebaseUid(uid)
                    .orElseGet(() -> userRepository.save(
                            User.builder()
                                    .firebaseUid(uid)
                                    .email(email != null ? email : ("uid:" + uid))
                                    .role(Role.USER)
                                    .build()
                    ));

            List<SimpleGrantedAuthority> authorities = List.of(
                    new SimpleGrantedAuthority("ROLE_" + user.getRole().name())
            );

            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(user.getFirebaseUid(), null, authorities);

            authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
            SecurityContextHolder.getContext().setAuthentication(authentication);
            contextSetByThisFilter = true;

            // Useful attributes for controllers/services
            request.setAttribute("firebaseEmail", email);
            request.setAttribute("firebaseEmailVerified", emailVerified);

            filterChain.doFilter(request, response);

        } catch (Exception ex) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        } finally {
            // IMPORTANT: In dev profile (no SecurityFilterChain context cleanup), avoid thread-local leaks.
            if (contextSetByThisFilter) {
                SecurityContextHolder.clearContext();
            }
        }
    }
}
