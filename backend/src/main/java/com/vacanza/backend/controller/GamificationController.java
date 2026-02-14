package com.vacanza.backend.controller;

import com.vacanza.backend.dto.response.GamificationProfileDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.GamificationProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/gamification")
@RequiredArgsConstructor
public class GamificationController {

    private final GamificationProfileService profileService;
    private final CurrentUserProvider currentUserProvider;

    @GetMapping("/profile")
    public ResponseEntity<GamificationProfileDTO> getProfile() {
        User user = currentUserProvider.getCurrentUserEntity();
        return ResponseEntity.ok(profileService.getProfile(user));
    }
}
