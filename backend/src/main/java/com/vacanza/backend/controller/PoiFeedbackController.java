package com.vacanza.backend.controller;

import com.vacanza.backend.dto.enums.PoiFeedbackEventType;
import com.vacanza.backend.dto.internal.PoiFeedbackContext;
import com.vacanza.backend.dto.request.PoiFeedbackEventRequestDTO;
import com.vacanza.backend.dto.request.RouteFeedbackRequestDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.UserFeedbackService;
import com.vacanza.backend.service.UserRouteFeedbackService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/feedback")
@RequiredArgsConstructor
public class PoiFeedbackController {

    private final CurrentUserProvider currentUserProvider;
    private final UserFeedbackService userFeedbackService;
    private final UserRouteFeedbackService userRouteFeedbackService;

    /**
     * Current user's aggregated POI and category affinity scores (for UI thumb state after refresh).
     */
    @GetMapping("/affinity")
    public ResponseEntity<Map<String, Map<String, Double>>> getAffinity() {
        User user = currentUserProvider.getCurrentUserEntity();
        PoiFeedbackContext ctx = userFeedbackService.buildContext(user.getUserId());
        return ResponseEntity.ok(Map.of(
                "poiScores", ctx.poiScores(),
                "categoryScores", ctx.categoryScores()));
    }

    /**
     * Thumbs up/down on a saved {@link com.vacanza.backend.entity.AiRoute} row (user-scoped).
     */
    @PostMapping("/route")
    public ResponseEntity<Void> recordRouteFeedback(@RequestBody RouteFeedbackRequestDTO body) {
        User user = currentUserProvider.getCurrentUserEntity();
        if (body == null || body.routeId() == null || body.eventType() == null || body.eventType().isBlank()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
        PoiFeedbackEventType type = PoiFeedbackEventType.fromApi(body.eventType());
        if (type != PoiFeedbackEventType.THUMBS_UP && type != PoiFeedbackEventType.THUMBS_DOWN) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
        try {
            userRouteFeedbackService.upsertFromThumbs(user, body.routeId(), type);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
        return ResponseEntity.accepted().build();
    }

    @PostMapping("/poi-events")
    public ResponseEntity<Void> recordPoiEvent(@RequestBody PoiFeedbackEventRequestDTO body) {
        User user = currentUserProvider.getCurrentUserEntity();
        if (body == null || body.eventType() == null || body.eventType().isBlank()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
        if (PoiFeedbackEventType.fromApi(body.eventType()) == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
        userFeedbackService.record(user, body);
        return ResponseEntity.accepted().build();
    }
}
