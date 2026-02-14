package com.vacanza.backend.controller;

import com.vacanza.backend.dto.AutoCheckInRequestDTO;
import com.vacanza.backend.dto.CheckInResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.impl.CheckInImpl;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/checkins")
@RequiredArgsConstructor
public class CheckInController {

    private final CheckInImpl checkInService;
    private final CurrentUserProvider currentUserProvider;

    @PostMapping("/auto")
    public ResponseEntity<CheckInResponseDTO> autoCheckIn(@Valid @RequestBody AutoCheckInRequestDTO request) {
        User currentUser = currentUserProvider.getCurrentUserEntity();
        CheckInResponseDTO response = checkInService.evaluateAutoCheckIn(currentUser, request);
        return ResponseEntity.ok(response);
    }
}
