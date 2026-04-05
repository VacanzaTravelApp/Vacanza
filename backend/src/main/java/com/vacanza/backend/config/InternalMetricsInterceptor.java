package com.vacanza.backend.config;

import com.vacanza.backend.component.ApiMetricsCollector;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * Intercepts incoming internal REST requests to track latencies
 * using ApiMetricsCollector for the Admin panel.
 */
@Component
@RequiredArgsConstructor
public class InternalMetricsInterceptor implements HandlerInterceptor {

    private final ApiMetricsCollector apiMetricsCollector;
    private static final String START_TIME_ATTR = "InternalMetricsInterceptor.startTime";

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        request.setAttribute(START_TIME_ATTR, System.currentTimeMillis());
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        Long startTime = (Long) request.getAttribute(START_TIME_ATTR);
        if (startTime != null) {
            long duration = System.currentTimeMillis() - startTime;
            
            // Extract the base path up to the second slash. E.g. /pois/123 -> /pois
            String uri = request.getRequestURI();
            String[] segments = uri.split("/");
            String apiName = "Internal API";
            if (segments.length >= 2) {
                apiName = "Internal: /" + segments[1];
                if (segments.length >= 3 && segments[1].equals("api")) {
                    apiName = "Internal: /api/" + segments[2];
                }
            } else {
                apiName = "Internal: " + uri;
            }
            
            // If the status is 5xx, or there is an unhandled exception, count it as an internal server error.
            if (response.getStatus() >= 500 || ex != null) {
                apiMetricsCollector.recordError(apiName);
            } else {
                apiMetricsCollector.recordCall(apiName, duration);
            }
        }
    }
}
