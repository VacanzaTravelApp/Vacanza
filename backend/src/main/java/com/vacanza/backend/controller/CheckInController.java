package com.vacanza.backend.controller;

import com.vacanza.backend.dto.request.AutoCheckInRequestDTO;
import com.vacanza.backend.dto.response.CheckInHistoryDTO;
import com.vacanza.backend.dto.response.CheckInResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.CheckInService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/users/me/checkins")
@RequiredArgsConstructor
public class CheckInController {

    private final CheckInService checkInService;
    private final CurrentUserProvider currentUserProvider;

    @PostMapping("/auto")
    public ResponseEntity<CheckInResponseDTO> autoCheckIn(@Valid @RequestBody AutoCheckInRequestDTO request) {
        User currentUser = currentUserProvider.getCurrentUserEntity();
        CheckInResponseDTO response = checkInService.evaluateAutoCheckIn(currentUser, request);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    public ResponseEntity<List<CheckInHistoryDTO>> getCheckInHistory() {
        User currentUser = currentUserProvider.getCurrentUserEntity();
        List<CheckInHistoryDTO> history = checkInService.getCheckInHistory(currentUser);
        return ResponseEntity.ok(history);
    }
}
