package com.vacanza.backend.controller;

import com.vacanza.backend.dto.request.AccommodationSearchRequestDTO;
import com.vacanza.backend.dto.request.TransportSearchRequestDTO;
import com.vacanza.backend.dto.response.AccommodationOptionDTO;
import com.vacanza.backend.dto.response.DestinationSuggestionDTO;
import com.vacanza.backend.dto.response.TransportOptionDTO;
import com.vacanza.backend.exceptions.BookingException;
import com.vacanza.backend.integration.booking.SerpApiAirportSuggestion;
import com.vacanza.backend.service.BookingService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Slf4j
@Validated
@RestController
@RequestMapping("/bookings")
@RequiredArgsConstructor
public class BookingController {

    private final BookingService bookingService;

    @PostMapping("/accommodations/search")
    public ResponseEntity<List<AccommodationOptionDTO>> searchAccommodations(
            @Valid @RequestBody AccommodationSearchRequestDTO request) {

        log.info("Accommodation search request: query={}", request.getQuery());
        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);
        return ResponseEntity.ok(results);
    }

    @PostMapping("/transportation/search")
    public ResponseEntity<List<TransportOptionDTO>> searchTransportation(
            @Valid @RequestBody TransportSearchRequestDTO request) {

        log.info("Transportation search request: {} -> {}", request.getOrigin(), request.getDestination());
        List<TransportOptionDTO> results = bookingService.searchTransportation(request);
        return ResponseEntity.ok(results);
    }

    /**
     * Airport / city name autocomplete for the flight search UI.
     *
     * <p>Designed for type-ahead widgets: call this endpoint as the user types
     * (debounced, minimum 2 characters) and display the returned suggestions.
     * The user selects one; its {@code iataCode} is then used as the
     * {@code origin} or {@code destination} in the flight search request.
     *
     * @param q partial airport or city name (e.g. "istan", "New York", "Heath")
     * @return sorted list of matching airport/city suggestions
     */
    @GetMapping("/airports/search")
    public ResponseEntity<List<SerpApiAirportSuggestion>> searchAirports(
            @RequestParam
            @Size(min = 2, message = "Query must be at least 2 characters")
            String q) {

        log.info("Airport autocomplete request: q='{}'", q);
        List<SerpApiAirportSuggestion> results = bookingService.searchAirports(q);
        return ResponseEntity.ok(results);
    }

    /**
     * Hotel destination autocomplete for the accommodation search UI.
     *
     * <p>Reuses the airport autocomplete data under the hood — so this endpoint
     * does NOT make any extra SerpAPI calls. Returns unique city+country
     * pairs with pre-built search queries like "Hotels in Istanbul".
     *
     * @param q partial city or destination name (e.g. "istan", "paris")
     * @return unique destination suggestions with display names
     */
    @GetMapping("/destinations/search")
    public ResponseEntity<List<DestinationSuggestionDTO>> searchDestinations(
            @RequestParam
            @Size(min = 2, message = "Query must be at least 2 characters")
            String q) {

        log.info("Destination autocomplete request: q='{}'", q);
        List<DestinationSuggestionDTO> results = bookingService.searchDestinations(q);
        return ResponseEntity.ok(results);
    }

    @ExceptionHandler(BookingException.class)
    public ResponseEntity<Map<String, String>> handleBookingException(BookingException ex) {
        log.error("Booking error: {} ({})", ex.getMessage(), ex.getStatus());
        return ResponseEntity.status(ex.getStatus())
                .body(Map.of(
                        "error", ex.getStatus().getReasonPhrase(),
                        "message", ex.getMessage()));
    }

    @ExceptionHandler(jakarta.validation.ConstraintViolationException.class)
    public ResponseEntity<Map<String, String>> handleConstraintViolation(
            jakarta.validation.ConstraintViolationException ex) {
        String message = ex.getConstraintViolations().stream()
                .map(v -> v.getMessage())
                .findFirst()
                .orElse("Validation error");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("error", "Bad Request", "message", message));
    }
}
