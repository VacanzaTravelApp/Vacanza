package com.vacanza.backend.dev;

import com.vacanza.backend.entity.CheckIn;
import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.enums.CheckInSource;
import com.vacanza.backend.event.CheckInCompletedEvent;
import com.vacanza.backend.repo.CheckInRepository;
import com.vacanza.backend.repo.PointOfInterestRepository;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.GamificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Dev-only controller for simulating check-ins during demos/presentations.
 * NOT available in production — only active when spring.profiles.active=dev.
 */
@RestController
@RequestMapping("/dev/gamification")
@Profile("dev")
@RequiredArgsConstructor
@Slf4j
public class DevGamificationController {

    private final CurrentUserProvider currentUserProvider;
    private final PointOfInterestRepository poiRepository;
    private final CheckInRepository checkInRepository;
    private final GamificationService gamificationService;

    /**
     * Simulate a check-in for the current user without GPS verification.
     * Creates a real check-in record and triggers gamification processing
     * synchronously.
     *
     * POST /dev/gamification/simulate-checkin
     * { "poiId": "uuid-here" }
     */
    @PostMapping("/simulate-checkin")
    public ResponseEntity<Map<String, Object>> simulateCheckIn(@RequestBody Map<String, String> body) {
        User user = currentUserProvider.getCurrentUserEntity();
        UUID poiId = UUID.fromString(body.get("poiId"));

        PointOfInterest poi = poiRepository.findById(poiId)
                .orElseThrow(() -> new IllegalArgumentException("POI not found: " + poiId));

        // Check duplicate
        if (checkInRepository.existsByUserAndPointOfInterest(user, poi)) {
            return ResponseEntity.ok(Map.of(
                    "success", false,
                    "message", "Already checked in to " + poi.getName()));
        }

        // Create check-in
        CheckIn checkIn = CheckIn.builder()
                .user(user)
                .pointOfInterest(poi)
                .checkedInAt(Instant.now())
                .source(CheckInSource.MANUAL)
                .build();
        CheckIn saved = checkInRepository.save(checkIn);

        // Trigger gamification synchronously (not async — we want immediate feedback in
        // demo)
        CheckInCompletedEvent event = CheckInCompletedEvent.builder()
                .checkInId(saved.getCheckInId())
                .userId(user.getUserId())
                .poiId(poi.getPoiId())
                .poiName(poi.getName())
                .checkedInAt(saved.getCheckedInAt())
                .source(saved.getSource())
                .build();

        gamificationService.processCheckIn(event);

        log.info("[DEV] Simulated check-in: userId={}, poi={}", user.getUserId(), poi.getName());

        return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Simulated check-in to " + poi.getName(),
                "checkInId", saved.getCheckInId().toString()));
    }
}
