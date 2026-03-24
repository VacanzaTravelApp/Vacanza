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
import java.util.Set;

/**
 * Validates Firebase ID Token sent by frontend:
 * Authorization: Bearer <firebase_id_token>
 *
 * Behavior:
 * - OPTIONS (preflight) requests are always allowed.
 * - If Authorization header is missing or not Bearer => do nothing, continue
 * filter chain.
 * (SecurityConfig decides if endpoint is public or requires authentication.)
 * - If Bearer token is present:
 * - verify token using Firebase Admin SDK
 * - ensure user exists in DB (users table)
 * - check emailVerified flag — block unverified users (except whitelisted
 * paths)
 * - set SecurityContext principal=firebaseUid, authority=ROLE_*
 * - attach request attributes: firebaseEmail, firebaseEmailVerified
 * - If Bearer token is present but invalid/expired => 401
 * - If Bearer token is valid but emailVerified=false => 403 (except whitelisted
 * paths)
 */
@Component
public class FirebaseTokenFilter extends OncePerRequestFilter {

    private final UserRepository userRepository;

    /**
     * Unverified users can only access these paths.
     * /auth/me, /auth/login → frontend needs to check user status
     * /auth/register → profile completion after Firebase signup
     * /auth/logout → user should be able to logout
     */
    private static final Set<String> UNVERIFIED_ALLOWED_PATHS = Set.of(
            "/auth/me",
            "/auth/login",
            "/auth/register",
            "/auth/logout");

    public FirebaseTokenFilter(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {

        // Preflight is not an authenticated request; let it pass.
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        String header = request.getHeader(HttpHeaders.AUTHORIZATION);

        // No bearer -> just continue.
        // Public endpoints will succeed; protected endpoints will be blocked by
        // SecurityConfig.
        if (header == null || !header.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            String token = header.substring("Bearer ".length()).trim();

            // Verify Firebase ID token (throws if invalid/expired)
            FirebaseToken decoded = FirebaseAuth.getInstance().verifyIdToken(token);

            String uid = decoded.getUid();
            String email = decoded.getEmail(); // can be null
            boolean emailVerified = Boolean.TRUE.equals(decoded.isEmailVerified());

            // DB sync: create user if missing
            User user = userRepository.findByFirebaseUid(uid).orElseGet(() -> userRepository.save(
                    User.builder()
                            .firebaseUid(uid)
                            // If email is null, set a safe placeholder to avoid null constraints.
                            .email(email != null ? email : ("uid:" + uid))
                            .role(Role.USER)
                            .build()));

            List<SimpleGrantedAuthority> authorities = List.of(
                    new SimpleGrantedAuthority("ROLE_" + user.getRole().name()));

            UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                    user.getFirebaseUid(), null, authorities);

            authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
            SecurityContextHolder.getContext().setAuthentication(authentication);

            // Useful attributes for services/controllers (AuthService reads this)
            request.setAttribute("firebaseEmail", email);
            request.setAttribute("firebaseEmailVerified", emailVerified);

            // Block unverified users from protected endpoints
            if (!emailVerified && !UNVERIFIED_ALLOWED_PATHS.contains(request.getRequestURI())) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.setContentType("application/json");
                response.getWriter().write(
                        "{\"status\":403,\"error\":\"Forbidden\","
                                + "\"message\":\"Account not verified. Please verify your email first.\","
                                + "\"path\":\"" + request.getRequestURI() + "\"}");
                return;
            }

            filterChain.doFilter(request, response);

        } catch (Exception ex) {
            // Token invalid/expired/verification failed (only when Bearer is present)
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write(
                    "{\"status\":401,\"error\":\"Unauthorized\","
                            + "\"message\":\"Invalid or expired token. Please re-authenticate.\","
                            + "\"path\":\"" + request.getRequestURI() + "\"}");
        }
    }
}