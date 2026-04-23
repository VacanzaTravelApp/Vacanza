package com.vacanza.backend.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
@RequiredArgsConstructor
public class WebMvcConfig implements WebMvcConfigurer {

    private final InternalMetricsInterceptor internalMetricsInterceptor;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // Only track API endpoints to avoid static resources or root mappings cluttering metrics
        registry.addInterceptor(internalMetricsInterceptor)
                .addPathPatterns("/**")
                .excludePathPatterns("/error", "/actuator/**");
    }
}
