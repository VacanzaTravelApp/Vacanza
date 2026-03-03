package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.UserInteractionRequestDTO;
import com.vacanza.backend.dto.response.InteractionStatsResponseDTO;
import com.vacanza.backend.dto.response.UserInteractionResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserInteraction;
import com.vacanza.backend.entity.enums.InteractionType;
import com.vacanza.backend.repo.UserInteractionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserInteractionService {

    private static final long ANALYSIS_EVERY_N = 10;

    private final UserInteractionRepository userInteractionRepository;
    private final BehaviorAnalysisService behaviorAnalysisService;

    @Transactional
    public UserInteractionResponseDTO track(User user, UserInteractionRequestDTO request) {
        InteractionType type = InteractionType.fromApi(request.getInteractionType());
        if (type == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Invalid interaction_type: " + request.getInteractionType());
        }

        UserInteraction interaction = UserInteraction.builder()
                .user(user)
                .interactionType(type)
                .targetId(request.getTargetId())
                .metadata(request.getMetadata())
                .build();

        UserInteraction saved = userInteractionRepository.save(interaction);

        triggerAnalysisIfNeeded(user);

        return UserInteractionResponseDTO.builder()
                .interactionId(saved.getInteractionId())
                .success(true)
                .build();
    }

    @Transactional(readOnly = true)
    public InteractionStatsResponseDTO getStats(User user) {
        long totalCount = userInteractionRepository.countByUser(user);
        List<Object[]> rows = userInteractionRepository.countInteractionTypesByUser(user.getUserId());

        var byType = rows.stream()
                .map(row -> InteractionStatsResponseDTO.TypeCount.builder()
                        .interactionType((String) row[0])
                        .count(((Number) row[1]).longValue())
                        .build())
                .toList();

        return InteractionStatsResponseDTO.builder()
                .totalCount(totalCount)
                .byType(byType)
                .build();
    }

    private void triggerAnalysisIfNeeded(User user) {
        try {
            long totalInteractions = userInteractionRepository.countByUser(user);
            if (totalInteractions > 0 && totalInteractions % ANALYSIS_EVERY_N == 0) {
                log.info("Triggering behavior analysis for user {} (interaction #{})",
                        user.getUserId(), totalInteractions);
                behaviorAnalysisService.analyzeAndSavePreferences(user);
            }
        } catch (Exception e) {
            log.warn("Behavior analysis failed (non-blocking): {}", e.getMessage());
        }
    }
}
