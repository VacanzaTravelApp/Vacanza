package com.vacanza.backend.controller;

import com.vacanza.backend.dto.response.TravelStatsDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.TravelStatsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
public class TravelStatsController {

    private final TravelStatsService travelStatsService;
    private final CurrentUserProvider currentUserProvider;

    @GetMapping("/stats")
    public ResponseEntity<TravelStatsDTO> getStats() {
        User currentUser = currentUserProvider.getCurrentUserEntity();
        TravelStatsDTO stats = travelStatsService.getStats(currentUser);
        return ResponseEntity.ok(stats);
    }
}
