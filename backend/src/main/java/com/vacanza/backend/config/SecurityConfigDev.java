package com.vacanza.backend.config;

import com.vacanza.backend.security.FirebaseTokenFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * DEV environment:
 * - All endpoints are reachable without auth (permitAll)
 * - BUT if a Bearer token is provided, we still validate it and set SecurityContext
 * so /auth/me and profile endpoints work with curl tests.
 */

@Configuration
@Profile("dev")
public class SecurityConfigDev {

    private final FirebaseTokenFilter firebaseTokenFilter;

    public SecurityConfigDev(FirebaseTokenFilter firebaseTokenFilter) {
        this.firebaseTokenFilter = firebaseTokenFilter;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth.anyRequest().permitAll())
                .httpBasic(httpBasic -> httpBasic.disable())
                .formLogin(form -> form.disable())
                // token varsa context set edebilmek için dev'de de ekliyoruz
                .addFilterBefore(firebaseTokenFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}