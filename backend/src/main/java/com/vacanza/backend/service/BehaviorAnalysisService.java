package com.vacanza.backend.service;

import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserPreferenceAi;
import com.vacanza.backend.repo.UserInteractionRepository;
import com.vacanza.backend.repo.UserPreferenceAiRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Analyzes user_interactions to infer preferences from behavior.
 * Triggered every N interactions (see ANALYSIS_THRESHOLD).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BehaviorAnalysisService {

    private static final String SOURCE_BEHAVIOR = "BEHAVIOR";
    private static final String KEY_CATEGORY_PREFERENCE = "category_preference";
    private static final int MIN_INTERACTIONS_FOR_CATEGORY = 2;

    /**
     * POI_FAVORITE carries more signal than POI_VIEW.
     * CATEGORY_FILTER is an explicit intent signal.
     */
    private static final double WEIGHT_POI_VIEW = 1.0;
    private static final double WEIGHT_POI_FAVORITE = 3.0;
    private static final double WEIGHT_CATEGORY_FILTER = 2.0;

    private final UserInteractionRepository interactionRepository;
    private final UserPreferenceAiRepository preferenceAiRepository;

    /**
     * Analyze all interactions for a user and upsert category_preference
     * into user_preferences_ai with source=BEHAVIOR.
     */
    private static final Map<String, Double> INTERACTION_WEIGHTS = Map.of(
            "POI_VIEW", WEIGHT_POI_VIEW,
            "POI_FAVORITE", WEIGHT_POI_FAVORITE
    );

    @Transactional
    public void analyzeAndSavePreferences(User user) {
        Map<String, Double> categoryScores = new LinkedHashMap<>();

        // POI interactions: each row is [interaction_type, category, count]
        List<Object[]> poiCategories = interactionRepository
                .countPoiCategoriesByUser(user.getUserId());
        for (Object[] row : poiCategories) {
            String interactionType = (String) row[0];
            String category = (String) row[1];
            long count = ((Number) row[2]).longValue();
            double weight = INTERACTION_WEIGHTS.getOrDefault(interactionType, WEIGHT_POI_VIEW);
            categoryScores.merge(category, count * weight, Double::sum);
        }

        // Category filter interactions: each row is [category, count]
        List<Object[]> filterCategories = interactionRepository
                .countFilterCategoriesByUser(user.getUserId());
        for (Object[] row : filterCategories) {
            String category = (String) row[0];
            long count = ((Number) row[1]).longValue();
            categoryScores.merge(category, count * WEIGHT_CATEGORY_FILTER, Double::sum);
        }

        if (categoryScores.isEmpty()) {
            log.debug("No category data for user {}, skipping behavior analysis", user.getUserId());
            return;
        }

        List<Map.Entry<String, Double>> sorted = categoryScores.entrySet().stream()
                .filter(e -> e.getValue() >= MIN_INTERACTIONS_FOR_CATEGORY)
                .sorted(Map.Entry.<String, Double>comparingByValue().reversed())
                .toList();

        if (sorted.isEmpty()) {
            return;
        }

        double maxScore = sorted.get(0).getValue();
        String topCategories = sorted.stream()
                .limit(5)
                .map(Map.Entry::getKey)
                .collect(Collectors.joining(", "));

        double confidence = Math.min(1.0, 0.5 + (maxScore / 20.0) * 0.5);

        upsertPreference(user, KEY_CATEGORY_PREFERENCE, topCategories, confidence);

        log.info("Behavior analysis for user {}: category_preference = {} (confidence: {})",
                user.getUserId(), topCategories, String.format("%.2f", confidence));
    }

    private void upsertPreference(User user, String key, String value, double confidence) {
        UserPreferenceAi existing = preferenceAiRepository
                .findByUserAndPreferenceKey(user, key)
                .orElse(null);

        if (existing != null) {
            existing.setPreferenceValue(value);
            existing.setConfidence(confidence);
            existing.setSource(SOURCE_BEHAVIOR);
            preferenceAiRepository.save(existing);
        } else {
            UserPreferenceAi pref = UserPreferenceAi.builder()
                    .user(user)
                    .preferenceKey(key)
                    .preferenceValue(value)
                    .confidence(confidence)
                    .source(SOURCE_BEHAVIOR)
                    .build();
            preferenceAiRepository.save(pref);
        }
    }
}
