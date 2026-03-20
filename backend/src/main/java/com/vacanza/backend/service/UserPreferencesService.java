package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.UserPreferencesRequestDTO;
import com.vacanza.backend.dto.response.UserPreferencesResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserPreferences;
import com.vacanza.backend.repo.UserPreferencesRepository;
import com.vacanza.backend.security.CurrentUserProvider;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;

/**
 * Upsert for user travel preferences.
 * - If preferences don't exist yet → create with provided values.
 * - If they exist → update only non-null fields (partial update).
 */
@Service
@AllArgsConstructor
public class UserPreferencesService {

    private final CurrentUserProvider currentUserProvider;
    private final UserPreferencesRepository preferencesRepository;

    @Transactional(readOnly = true)
    public UserPreferencesResponseDTO getPreferences() {
        User user = currentUserProvider.getCurrentUserEntity();
        UserPreferences prefs = preferencesRepository.findByUser(user)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "User preferences not found"));
        return toDto(prefs);
    }

    /**
     * Get preferences by User entity (for internal use, e.g. AI chat proxy).
     * Returns empty if preferences not set yet.
     */
    @Transactional(readOnly = true)
    public Optional<UserPreferencesResponseDTO> getPreferencesByUser(User user) {
        return preferencesRepository.findByUser(user).map(this::toDto);
    }

    @Transactional
    public UserPreferencesResponseDTO updatePreferences(UserPreferencesRequestDTO req) {
        User user = currentUserProvider.getCurrentUserEntity();
        UserPreferences prefs = preferencesRepository.findByUser(user).orElse(null);

        if (prefs == null) {
            // First time — create
            prefs = UserPreferences.builder()
                    .user(user)
                    .travelStyle(req.getTravelStyle())
                    .favoriteCategories(req.getFavoriteCategories())
                    .activityLevel(req.getActivityLevel())
                    .cuisinePreferences(req.getCuisinePreferences())
                    .preferredClimate(req.getPreferredClimate())
                    .tripPace(req.getTripPace())
                    .accommodationType(req.getAccommodationType())
                    .transportPreference(req.getTransportPreference())
                    .dietaryRestrictions(req.getDietaryRestrictions())
                    .accessibilityNeeds(req.getAccessibilityNeeds())
                    .avoidCategories(req.getAvoidCategories())
                    .dailyBudget(req.getDailyBudget())
                    .budgetCurrency(req.getBudgetCurrency())
                    .splurgeCategories(req.getSplurgeCategories())
                    .preferredLanguage(req.getPreferredLanguage())
                    .spokenLanguages(req.getSpokenLanguages())
                    .build();

            return toDto(preferencesRepository.save(prefs));
        }

        // Update: only apply non-null values
        if (req.getTravelStyle() != null)
            prefs.setTravelStyle(req.getTravelStyle());
        if (req.getFavoriteCategories() != null)
            prefs.setFavoriteCategories(req.getFavoriteCategories());
        if (req.getActivityLevel() != null)
            prefs.setActivityLevel(req.getActivityLevel());
        if (req.getCuisinePreferences() != null)
            prefs.setCuisinePreferences(req.getCuisinePreferences());

        if (req.getPreferredClimate() != null)
            prefs.setPreferredClimate(req.getPreferredClimate());
        if (req.getTripPace() != null)
            prefs.setTripPace(req.getTripPace());
        if (req.getAccommodationType() != null)
            prefs.setAccommodationType(req.getAccommodationType());
        if (req.getTransportPreference() != null)
            prefs.setTransportPreference(req.getTransportPreference());

        if (req.getDietaryRestrictions() != null)
            prefs.setDietaryRestrictions(req.getDietaryRestrictions());
        if (req.getAccessibilityNeeds() != null)
            prefs.setAccessibilityNeeds(req.getAccessibilityNeeds());
        if (req.getAvoidCategories() != null)
            prefs.setAvoidCategories(req.getAvoidCategories());

        if (req.getDailyBudget() != null)
            prefs.setDailyBudget(req.getDailyBudget());
        if (req.getBudgetCurrency() != null)
            prefs.setBudgetCurrency(req.getBudgetCurrency());
        if (req.getSplurgeCategories() != null)
            prefs.setSplurgeCategories(req.getSplurgeCategories());

        if (req.getPreferredLanguage() != null)
            prefs.setPreferredLanguage(req.getPreferredLanguage());
        if (req.getSpokenLanguages() != null)
            prefs.setSpokenLanguages(req.getSpokenLanguages());

        return toDto(preferencesRepository.save(prefs));
    }

    private UserPreferencesResponseDTO toDto(UserPreferences prefs) {
        return UserPreferencesResponseDTO.builder()
                .preferencesId(prefs.getPreferencesId())
                .userId(prefs.getUser().getUserId())
                .travelStyle(prefs.getTravelStyle())
                .favoriteCategories(prefs.getFavoriteCategories())
                .activityLevel(prefs.getActivityLevel())
                .cuisinePreferences(prefs.getCuisinePreferences())
                .preferredClimate(prefs.getPreferredClimate())
                .tripPace(prefs.getTripPace())
                .accommodationType(prefs.getAccommodationType())
                .transportPreference(prefs.getTransportPreference())
                .dietaryRestrictions(prefs.getDietaryRestrictions())
                .accessibilityNeeds(prefs.getAccessibilityNeeds())
                .avoidCategories(prefs.getAvoidCategories())
                .dailyBudget(prefs.getDailyBudget())
                .budgetCurrency(prefs.getBudgetCurrency())
                .splurgeCategories(prefs.getSplurgeCategories())
                .preferredLanguage(prefs.getPreferredLanguage())
                .spokenLanguages(prefs.getSpokenLanguages())
                .createdAt(prefs.getCreatedAt())
                .updatedAt(prefs.getUpdatedAt())
                .build();
    }
}
