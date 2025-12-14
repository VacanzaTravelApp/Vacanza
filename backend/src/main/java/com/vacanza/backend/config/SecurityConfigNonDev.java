package com.vacanza.backend.config;

import com.vacanza.backend.security.FirebaseTokenFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * non-dev security configuration.
 * stateless API
 * requires Firebase Bearer token for protected endpoints
 * adds FirebaseTokenFilter to validate Firebase ID tokens
 */

@Configuration
@Profile("!dev")
public class SecurityConfigNonDev {

    private final FirebaseTokenFilter firebaseTokenFilter;

    public SecurityConfigNonDev(FirebaseTokenFilter firebaseTokenFilter) {
        this.firebaseTokenFilter = firebaseTokenFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .httpBasic(hb -> hb.disable())
                .formLogin(fl -> fl.disable())
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/health", "/error").permitAll()
                        // anonymous ROLE_ANONYMOUS olduğu için buradan geçemez
                        .anyRequest().hasAnyRole("USER", "ADMIN")
                )
                .addFilterBefore(firebaseTokenFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
