package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.UserInteractionRequestDTO;
import com.vacanza.backend.dto.response.UserInteractionResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserInteraction;
import com.vacanza.backend.entity.enums.InteractionType;
import com.vacanza.backend.repo.UserInteractionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
@RequiredArgsConstructor
public class UserInteractionService {

    private final UserInteractionRepository userInteractionRepository;

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

        return UserInteractionResponseDTO.builder()
                .interactionId(saved.getInteractionId())
                .success(true)
                .build();
    }
}
