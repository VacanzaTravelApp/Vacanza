package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Response DTO for GET /admin/monitoring (UC2.1).
 * Contains system health, service statuses, API usage metrics, and recent logs.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SystemMonitoringDTO {

    /**
     * Overall system health score (0.0 – 1.0).
     * Calculated as: servicesUp / totalServices.
     */
    private double systemHealth;

    /**
     * JVM uptime in seconds since server start.
     */
    private long uptimeSeconds;

    /**
     * ISO-8601 timestamp of when the server was started.
     */
    private String serverStartTime;

    /**
     * Current status of each backend service.
     */
    private List<ServiceStatus> services;

    /**
     * API usage metrics per external service (Ticketmaster, SerpApi, Foursquare, etc.).
     */
    private List<ApiUsageMetric> apiMetrics;

    /**
     * Recent system activity logs (last 50).
     */
    private List<LogEntry> logs;

    /**
     * ISO-8601 timestamp of when this data was generated.
     * Helps the frontend enforce the ≤ 60-second refresh interval (FReq13).
     */
    private String lastRefreshedAt;

    // ── Inner DTOs ──────────────────────────────────────────────

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ServiceStatus {
        private String name;     // e.g. "Auth Service", "POI / Maps API"
        private String status;   // "UP" or "DOWN"
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ApiUsageMetric {
        private String apiName;         // e.g. "Ticketmaster", "SerpApi"
        private long totalCalls;        // total API calls today
        private long errorCount;        // 4xx + 5xx responses today
        private long consecutiveErrors; // current streak of consecutive errors
        private double avgResponseMs;   // average response time in ms
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class LogEntry {
        private String timestamp;
        private String level;    // INFO, WARN, ERROR
        private String message;
        private String source;   // AUTH, TICKETMASTER, SERPAPI, SYSTEM
    }
}
