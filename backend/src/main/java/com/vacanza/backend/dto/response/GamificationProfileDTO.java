package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Gamification profile response matching the frontend contract.
 * All display texts are built by the backend — no hardcoding on frontend.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GamificationProfileDTO {

    private String roleText; // "Urban Adventurer"
    private String levelText; // "Level 5"
    private int xpProgressPercent; // 0-100
    private int xpToNextLevel; // XP needed for next level
    private int totalXp;
    private String badgesSectionTitle; // "Achievement Badges"

    private List<StatDTO> stats;
    private List<BadgeDTO> badges;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class StatDTO {
        private String label; // "Places", "Badges", "Days"
        private long value;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class BadgeDTO {
        private Long id;
        private String title; // "Explorer", "Foodie"
        private String key; // "explorer" — frontend maps to icon
        private boolean earned;
    }
}
