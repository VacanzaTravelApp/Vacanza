package com.vacanza.backend.config;

import com.vacanza.backend.security.FirebaseTokenFilter;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Prevent FirebaseTokenFilter from being auto-registered as a servlet filter.
 * We only want it inside Spring Security filter chain (added in SecurityConfig*).
 */
@Configuration
public class FirebaseTokenFilterRegistrationConfig {

    @Bean
    public FilterRegistrationBean<FirebaseTokenFilter> disableServletRegistration(FirebaseTokenFilter filter) {
        FilterRegistrationBean<FirebaseTokenFilter> registration = new FilterRegistrationBean<>(filter);
        registration.setEnabled(false);
        return registration;
    }
}