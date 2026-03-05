package com.vacanza.backend.integration.ai;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.vacanza.backend.dto.response.UserInfoResponseDTO;
import com.vacanza.backend.dto.response.UserPreferencesResponseDTO;
import lombok.Builder;
import lombok.Value;

import java.util.List;

/**
 * User profile for AI service (X-User-Profile header).
 * Combines identity (UserInfo) + travel preferences (UserPreferences).
 */
@Value
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class UserProfileForAi {

        // ── Identity (from UserInfo) ──────────────────────────────
        String displayName;
        String firstName;
        String middleName;
        String lastName;
        String preferredName;
        String country;
        String birthDate;
        String gender;
        String profileImageUrl;
        String joinDate;

        // ── Travel Style & Interests ──────────────────────────────
        String travelStyle;
        List<String> favoriteCategories;
        String activityLevel;
        List<String> cuisinePreferences;

        // ── Trip Preferences ──────────────────────────────────────
        String preferredClimate;
        String tripPace;
        String accommodationType;
        String transportPreference;

        // ── Constraints & Accessibility ───────────────────────────
        List<String> dietaryRestrictions;
        List<String> accessibilityNeeds;
        List<String> avoidCategories;

        // ── Budget Details ────────────────────────────────────────
        String dailyBudget;
        String budgetCurrency;
        List<String> splurgeCategories;

        // ── Language ──────────────────────────────────────────────
        String preferredLanguage;
        List<String> spokenLanguages;

        /**
         * Build AI profile from user info + optional preferences.
         */
        public static UserProfileForAi from(UserInfoResponseDTO info,
                        UserPreferencesResponseDTO prefs) {
                if (info == null)
                        return null;

                var b = UserProfileForAi.builder()
                                // Identity
                                .displayName(info.getDisplayName())
                                .firstName(info.getFirstName())
                                .middleName(info.getMiddleName())
                                .lastName(info.getLastName())
                                .preferredName(info.getPreferredName())
                                .country(info.getCountry())
                                .birthDate(info.getBirthDate() != null ? info.getBirthDate().toString() : null)
                                .gender(info.getGender() != null ? info.getGender().name() : null)
                                .profileImageUrl(info.getProfileImageUrl())
                                .joinDate(info.getJoinDate() != null ? info.getJoinDate().toString() : null);

                // Preferences (may be null if user hasn't set them yet)
                if (prefs != null) {
                        b.travelStyle(prefs.getTravelStyle() != null ? prefs.getTravelStyle().name() : null)
                                        .favoriteCategories(prefs.getFavoriteCategories())
                                        .activityLevel(prefs.getActivityLevel() != null
                                                        ? prefs.getActivityLevel().name()
                                                        : null)
                                        .cuisinePreferences(prefs.getCuisinePreferences())
                                        .preferredClimate(prefs.getPreferredClimate() != null
                                                        ? prefs.getPreferredClimate().name()
                                                        : null)
                                        .tripPace(prefs.getTripPace() != null ? prefs.getTripPace().name() : null)
                                        .accommodationType(
                                                        prefs.getAccommodationType() != null
                                                                        ? prefs.getAccommodationType().name()
                                                                        : null)
                                        .transportPreference(
                                                        prefs.getTransportPreference() != null
                                                                        ? prefs.getTransportPreference().name()
                                                                        : null)
                                        .dietaryRestrictions(prefs.getDietaryRestrictions())
                                        .accessibilityNeeds(prefs.getAccessibilityNeeds())
                                        .avoidCategories(prefs.getAvoidCategories())
                                        .dailyBudget(prefs.getDailyBudget() != null
                                                        ? prefs.getDailyBudget().toPlainString()
                                                        : null)
                                        .budgetCurrency(prefs.getBudgetCurrency())
                                        .splurgeCategories(prefs.getSplurgeCategories())
                                        .preferredLanguage(prefs.getPreferredLanguage())
                                        .spokenLanguages(prefs.getSpokenLanguages());
                }

                return b.build();
        }
}
