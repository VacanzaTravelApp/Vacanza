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
 validates Firebase ID Token sent by frontend:
 authorization: Bearer <firebase_id_token>
 If valid:
     db sync
     sets SecurityContext principal as firebaseUid
     adds role
 If invalid:
     responds with 401 Unauthorized
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

        String header = request.getHeader(HttpHeaders.AUTHORIZATION);

        // no bearer
        if (header == null || !header.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = header.substring("Bearer ".length()).trim();

        try {
            FirebaseToken decoded = FirebaseAuth.getInstance().verifyIdToken(token);

            String uid = decoded.getUid();
            String email = decoded.getEmail();
            boolean emailVerified = Boolean.TRUE.equals(decoded.isEmailVerified());

            //db sync
            User user = userRepository.findByFirebaseUid(uid)
                    .orElseGet(() -> userRepository.save(
                            User.builder()
                                    .firebaseUid(uid)
                                    .email(email)
                                    .role(Role.USER)
                                    .build()
                    ));

            //role based access (for later)
            List<SimpleGrantedAuthority> authorities = List.of(
                    new SimpleGrantedAuthority("ROLE_" + user.getRole().name())
            );

            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                            user.getFirebaseUid(), // principal
                            null,
                            authorities
                    );

            authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
            SecurityContextHolder.getContext().setAuthentication(authentication);

            //pass useful info down the chain
            request.setAttribute("firebaseEmail", email);
            request.setAttribute("firebaseEmailVerified", emailVerified);

            filterChain.doFilter(request, response);

        } catch (Exception ex) {
            //token invalid/expired/revoked
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        }
    }
}
