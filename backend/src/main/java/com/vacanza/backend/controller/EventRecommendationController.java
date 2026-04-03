package com.vacanza.backend.controller;

import com.vacanza.backend.dto.response.EventRecommendationResponse;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.EventRecommendationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;

/**
 * Event recommendations for a saved AI route (Ticketmaster + optional AI ranking).
 */
@Slf4j
@RestController
@RequestMapping("/routes")
@RequiredArgsConstructor
public class EventRecommendationController {

    private final EventRecommendationService eventRecommendationService;
    private final CurrentUserProvider currentUserProvider;

    @GetMapping("/{routeId}/event-recommendations")
    public ResponseEntity<EventRecommendationResponse> getRecommendations(@PathVariable UUID routeId) {
        User user = currentUserProvider.getCurrentUserEntity();
        try {
            EventRecommendationResponse body = eventRecommendationService.getRecommendations(routeId, user);
            return ResponseEntity.ok(body);
        } catch (ResponseStatusException e) {
            if (e.getStatusCode() == HttpStatus.NOT_FOUND) {
                throw e;
            }
            log.warn("Event recommendations failed for route {}: {}", routeId, e.getMessage());
            return ResponseEntity.ok(emptyBody());
        } catch (Exception e) {
            log.warn("Event recommendations failed for route {}: {}", routeId, e.getMessage(), e);
            return ResponseEntity.ok(emptyBody());
        }
    }

    private static EventRecommendationResponse emptyBody() {
        return EventRecommendationResponse.builder()
                .message(null)
                .events(List.of())
                .totalFound(0)
                .hasRecommendations(false)
                .build();
    }
}
