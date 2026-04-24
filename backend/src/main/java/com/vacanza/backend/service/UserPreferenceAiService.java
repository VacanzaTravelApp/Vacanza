package com.vacanza.backend.service;

import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserPreferenceAi;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.repo.UserPreferenceAiRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserPreferenceAiService {

    private static final String SOURCE_CHAT = "CHAT";

    private final UserPreferenceAiRepository repository;

    /**
     * Upsert AI-extracted preferences for a user.
     * <p>
     * When the AI returns multiple preferences with the <strong>same key</strong>
     * (e.g. three separate {@code event_interest} values), their values are merged
     * into a single comma-separated string and the highest confidence score is kept.
     * Existing DB values for the same key are also preserved (merged, deduplicated).
     * </p>
     */
    @Transactional
    public void saveExtractedPreferences(User user, List<AiChatDto.ExtractedPreference> preferences) {
        if (preferences == null || preferences.isEmpty()) {
            return;
        }

        // ── 1. Group incoming preferences by key, merge values & keep max confidence ──
        Map<String, MergedPref> grouped = new LinkedHashMap<>();
        for (AiChatDto.ExtractedPreference extracted : preferences) {
            if (extracted.getPreferenceKey() == null || extracted.getPreferenceValue() == null) {
                continue;
            }
            String key = extracted.getPreferenceKey().trim();
            grouped.merge(key,
                    new MergedPref(extracted.getPreferenceValue().trim(), extracted.getConfidence()),
                    MergedPref::merge);
        }

        // ── 2. Upsert each merged group, also merging with any existing DB value ──
        for (Map.Entry<String, MergedPref> entry : grouped.entrySet()) {
            String key = entry.getKey();
            MergedPref merged = entry.getValue();

            UserPreferenceAi existing = repository
                    .findByUserAndPreferenceKey(user, key)
                    .orElse(null);

            if (existing != null) {
                // Merge new values with the previously stored value
                String combinedValue = mergeValueStrings(existing.getPreferenceValue(), merged.value);
                existing.setPreferenceValue(combinedValue);
                existing.setConfidence(Math.max(
                        existing.getConfidence() != null ? existing.getConfidence() : 0.0,
                        merged.confidence));
                existing.setSource(SOURCE_CHAT);
                repository.save(existing);
                log.debug("Updated AI preference [{}] = {} (confidence: {})",
                        key, combinedValue, existing.getConfidence());
            } else {
                UserPreferenceAi newPref = UserPreferenceAi.builder()
                        .user(user)
                        .preferenceKey(key)
                        .preferenceValue(merged.value)
                        .confidence(merged.confidence)
                        .source(SOURCE_CHAT)
                        .build();
                repository.save(newPref);
                log.debug("Created AI preference [{}] = {} (confidence: {})",
                        key, merged.value, merged.confidence);
            }
        }

        log.info("Saved {} AI preferences ({} unique keys) for user {}",
                preferences.size(), grouped.size(), user.getUserId());
    }

    /**
     * Merge two comma-separated value strings, deduplicating entries (case-insensitive).
     * Example: mergeValueStrings("live music, football", "art, football") → "live music, football, art"
     */
    static String mergeValueStrings(String existing, String incoming) {
        LinkedHashSet<String> seen = new LinkedHashSet<>();
        addTokens(seen, existing);
        addTokens(seen, incoming);
        return String.join(", ", seen);
    }

    private static void addTokens(LinkedHashSet<String> seen, String csv) {
        if (csv == null || csv.isBlank()) return;
        for (String token : csv.split(",")) {
            String trimmed = token.trim();
            if (trimmed.isEmpty()) continue;
            // Dedup case-insensitively but keep original casing of the first occurrence
            boolean alreadyPresent = seen.stream()
                    .anyMatch(s -> s.equalsIgnoreCase(trimmed));
            if (!alreadyPresent) {
                seen.add(trimmed);
            }
        }
    }

    /** Helper to accumulate values and max-confidence for a single preference key. */
    private static final class MergedPref {
        String value;
        double confidence;

        MergedPref(String value, Double confidence) {
            this.value = value;
            this.confidence = confidence != null ? confidence : 0.0;
        }

        MergedPref merge(MergedPref other) {
            this.value = mergeValueStrings(this.value, other.value);
            this.confidence = Math.max(this.confidence, other.confidence);
            return this;
        }
    }

    /**
     * Get all AI preferences for a user as lightweight DTOs
     * (used to send as context to the extraction LLM).
     */
    @Transactional(readOnly = true)
    public List<AiChatDto.ExtractedPreference> getExistingPreferences(User user) {
        return repository.findByUser(user).stream()
                .map(p -> {
                    AiChatDto.ExtractedPreference dto = new AiChatDto.ExtractedPreference();
                    dto.setPreferenceKey(p.getPreferenceKey());
                    dto.setPreferenceValue(p.getPreferenceValue());
                    dto.setConfidence(p.getConfidence());
                    return dto;
                })
                .toList();
    }
}
