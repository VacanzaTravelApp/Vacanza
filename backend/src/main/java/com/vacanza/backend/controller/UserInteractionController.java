package com.vacanza.backend.controller;

import com.vacanza.backend.dto.request.UserInteractionRequestDTO;
import com.vacanza.backend.dto.response.InteractionStatsResponseDTO;
import com.vacanza.backend.dto.response.UserInteractionResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.UserInteractionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/behavior")
@RequiredArgsConstructor
public class UserInteractionController {

    private final UserInteractionService userInteractionService;
    private final CurrentUserProvider currentUserProvider;

    @GetMapping("/stats")
    public ResponseEntity<InteractionStatsResponseDTO> getStats() {
        User currentUser = currentUserProvider.getCurrentUserEntity();
        return ResponseEntity.ok(userInteractionService.getStats(currentUser));
    }

    @PostMapping("/track")
    public ResponseEntity<UserInteractionResponseDTO> track(@Valid @RequestBody UserInteractionRequestDTO request) {
        User currentUser = currentUserProvider.getCurrentUserEntity();
        UserInteractionResponseDTO response = userInteractionService.track(currentUser, request);
        return ResponseEntity.ok(response);
    }
}
