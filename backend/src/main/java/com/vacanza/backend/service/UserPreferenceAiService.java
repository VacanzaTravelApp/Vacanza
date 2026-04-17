package com.vacanza.backend.service;

import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserPreferenceAi;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.repo.UserPreferenceAiRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserPreferenceAiService {

    private static final String SOURCE_CHAT = "CHAT";

    private final UserPreferenceAiRepository repository;

    /**
     * Upsert AI-extracted preferences for a user.
     * For each preference: if the (user, key) pair exists, update value/confidence;
     * otherwise create a new record.
     */
    @Transactional
    public void saveExtractedPreferences(User user, List<AiChatDto.ExtractedPreference> preferences) {
        if (preferences == null || preferences.isEmpty()) {
            return;
        }

        for (AiChatDto.ExtractedPreference extracted : preferences) {
            if (extracted.getPreferenceKey() == null || extracted.getPreferenceValue() == null) {
                continue;
            }

            UserPreferenceAi existing = repository
                    .findByUserAndPreferenceKey(user, extracted.getPreferenceKey())
                    .orElse(null);

            if (existing != null) {
                existing.setPreferenceValue(extracted.getPreferenceValue());
                existing.setConfidence(extracted.getConfidence());
                existing.setSource(SOURCE_CHAT);
                repository.save(existing);
                log.debug("Updated AI preference [{}] = {} (confidence: {})",
                        extracted.getPreferenceKey(), extracted.getPreferenceValue(),
                        extracted.getConfidence());
            } else {
                UserPreferenceAi newPref = UserPreferenceAi.builder()
                        .user(user)
                        .preferenceKey(extracted.getPreferenceKey())
                        .preferenceValue(extracted.getPreferenceValue())
                        .confidence(extracted.getConfidence())
                        .source(SOURCE_CHAT)
                        .build();
                repository.save(newPref);
                log.debug("Created AI preference [{}] = {} (confidence: {})",
                        extracted.getPreferenceKey(), extracted.getPreferenceValue(),
                        extracted.getConfidence());
            }
        }

        log.info("Saved {} AI preferences for user {}", preferences.size(), user.getUserId());
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

    /**
     * Returns preferences resolved for a specific destination.
     * If a "category_preference:{destination}" entry exists, it replaces the global
     * "category_preference" in the returned list so the AI receives a single,
     * city-specific value instead of the generic one.
     * All other preference keys are returned unchanged.
     */
    @Transactional(readOnly = true)
    public List<AiChatDto.ExtractedPreference> getPreferencesForDestination(User user, String destination) {
        List<AiChatDto.ExtractedPreference> all = getExistingPreferences(user);
        if (destination == null || destination.isBlank()) return all;

        String destKey = "category_preference:" + destination.trim().toLowerCase(java.util.Locale.ROOT);

        // Check if a destination-specific category preference exists
        java.util.Optional<AiChatDto.ExtractedPreference> destPref = all.stream()
                .filter(p -> destKey.equals(p.getPreferenceKey()))
                .findFirst();

        if (destPref.isEmpty()) return all; // no override — use global as-is

        // Replace global "category_preference" with the destination-specific value,
        // and strip the raw "category_preference:{destination}" entry (not needed by AI)
        List<AiChatDto.ExtractedPreference> resolved = new ArrayList<>();
        for (AiChatDto.ExtractedPreference p : all) {
            if (p.getPreferenceKey().startsWith("category_preference:")) {
                continue; // skip all destination-specific entries from the list
            }
            if ("category_preference".equals(p.getPreferenceKey())) {
                // Override with destination-specific value
                AiChatDto.ExtractedPreference override = new AiChatDto.ExtractedPreference();
                override.setPreferenceKey("category_preference");
                override.setPreferenceValue(destPref.get().getPreferenceValue());
                override.setConfidence(destPref.get().getConfidence());
                resolved.add(override);
            } else {
                resolved.add(p);
            }
        }
        return resolved;
    }
}
