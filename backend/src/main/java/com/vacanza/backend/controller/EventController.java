package com.vacanza.backend.controller;

import com.vacanza.backend.dto.request.EventSearchRequestDTO;
import com.vacanza.backend.dto.response.EventDTO;
import com.vacanza.backend.exceptions.EventException;
import com.vacanza.backend.service.EventService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * REST controller for event search operations.
 * Follows the same pattern as BookingController.
 */
@Slf4j
@RestController
@RequestMapping("/events")
@RequiredArgsConstructor
public class EventController {

    private final EventService eventService;

    /**
     * Search for events by city, date range, and category.
     *
     * @param request search parameters
     * @return list of matching events
     */
    @PostMapping("/search")
    public ResponseEntity<List<EventDTO>> searchEvents(
            @Valid @RequestBody EventSearchRequestDTO request) {

        log.info("Event search request: city={}", request.getCity());
        List<EventDTO> results = eventService.searchEvents(request);
        return ResponseEntity.ok(results);
    }

    @ExceptionHandler(EventException.class)
    public ResponseEntity<Map<String, String>> handleEventException(EventException ex) {
        log.error("Event error: {} ({})", ex.getMessage(), ex.getStatus());
        return ResponseEntity.status(ex.getStatus())
                .body(Map.of(
                        "error", ex.getStatus().getReasonPhrase(),
                        "message", ex.getMessage()));
    }
}
