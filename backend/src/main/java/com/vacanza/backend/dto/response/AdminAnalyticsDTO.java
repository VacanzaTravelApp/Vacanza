package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Response DTO for GET /admin/analytics (UC2.2).
 * Contains user growth, check-in stats, category distribution, and top POIs.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminAnalyticsDTO {

    private long matrixUsers;
    private double globalRevenue;
    private long activeNodes;
    private double avgDuration;

    /**
     * Number of users who logged in within the last 30 minutes (approximate active sessions).
     */
    private long activeSessions;

    private List<GrowthMetric> growthTrajectory;
    private List<CategoryMetric> categoryBreakdown;
    private List<HighPerformanceAssetMetric> highPerformanceAssets;

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
    public static class GrowthMetric {
        private String period;    // e.g. "2026-01", "2026-02"
        private long newUsers;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CategoryMetric {
        private String name;   // e.g. "History", "Nature", "Culture"
        private long value;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class HighPerformanceAssetMetric {
        private String name;
        private String category;
        private double score;
    }
}
