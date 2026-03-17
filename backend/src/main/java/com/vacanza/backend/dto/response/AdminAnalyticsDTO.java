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

    private long totalUsers;
    private long activeSessions;
    private long totalCheckins;
    private List<GrowthMetric> growthTrends;
    private List<CategoryMetric> categoryDistribution;
    private List<TopPoiMetric> topPois;

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
        private String category;  // e.g. "History", "Nature", "Culture"
        private long count;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class TopPoiMetric {
        private String name;
        private String category;
        private long visitCount;
    }
}
