package com.vacanza.backend.service;

import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserPreferenceAi;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.repo.UserPreferenceAiRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
}
