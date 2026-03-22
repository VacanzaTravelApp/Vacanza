package com.vacanza.backend.controller;

import com.vacanza.backend.dto.enums.PoiFeedbackEventType;
import com.vacanza.backend.dto.request.PoiFeedbackEventRequestDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.UserFeedbackService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/feedback")
@RequiredArgsConstructor
public class PoiFeedbackController {

    private final CurrentUserProvider currentUserProvider;
    private final UserFeedbackService userFeedbackService;

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
