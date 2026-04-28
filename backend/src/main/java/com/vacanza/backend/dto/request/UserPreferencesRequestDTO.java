package com.vacanza.backend.dto.request;

import com.vacanza.backend.entity.enums.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserPreferencesRequestDTO {

    // Travel Style & Interests
    private TravelStyle travelStyle;
    private List<String> favoriteCategories;
    private ActivityLevel activityLevel;
    private List<String> cuisinePreferences;

    // Trip Preferences
    private PreferredClimate preferredClimate;
    private TripPace tripPace;
    private AccommodationType accommodationType;
    private TransportPreference transportPreference;

    // Constraints & Accessibility
    private List<String> dietaryRestrictions;
    private List<String> accessibilityNeeds;
    private List<String> avoidCategories;

    // Budget Details
    private BigDecimal dailyBudget;
    private String budgetCurrency;
    private List<String> splurgeCategories;

    // POI Limits
    private Integer maxDailyPois;

    // Language & Communication
    private String preferredLanguage;
    private List<String> spokenLanguages;
}
