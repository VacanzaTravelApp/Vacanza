package com.vacanza.backend.controller;

import com.vacanza.backend.dto.request.AccommodationSearchRequestDTO;
import com.vacanza.backend.dto.request.TransportSearchRequestDTO;
import com.vacanza.backend.dto.response.AccommodationOptionDTO;
import com.vacanza.backend.dto.response.TransportOptionDTO;
import com.vacanza.backend.exceptions.BookingException;
import com.vacanza.backend.service.BookingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/bookings")
@RequiredArgsConstructor
public class BookingController {

    private final BookingService bookingService;

    @PostMapping("/accommodations/search")
    public ResponseEntity<List<AccommodationOptionDTO>> searchAccommodations(
            @Valid @RequestBody AccommodationSearchRequestDTO request) {

        log.info("Accommodation search request: city={}", request.getCityCode());
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

    @ExceptionHandler(BookingException.class)
    public ResponseEntity<Map<String, String>> handleBookingException(BookingException ex) {
        log.error("Booking error: {} ({})", ex.getMessage(), ex.getStatus());
        return ResponseEntity.status(ex.getStatus())
                .body(Map.of(
                        "error", ex.getStatus().getReasonPhrase(),
                        "message", ex.getMessage()));
    }
}
