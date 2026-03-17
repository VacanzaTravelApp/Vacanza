package com.vacanza.backend.service.impl;

import com.vacanza.backend.dto.request.EventSearchRequestDTO;
import com.vacanza.backend.dto.response.EventDTO;
import com.vacanza.backend.integration.event.TicketmasterClient;
import com.vacanza.backend.service.EventService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Event service implementation that delegates to TicketmasterClient.
 * Follows the same pattern as BookingServiceImpl.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EventServiceImpl implements EventService {

    private final TicketmasterClient ticketmasterClient;

    @Override
    public List<EventDTO> searchEvents(EventSearchRequestDTO request) {
        log.info("Searching events: city={}, country={}, dates={}/{}, category={}",
                request.getCity(), request.getCountryCode(),
                request.getStartDate(), request.getEndDate(),
                request.getCategory());

        List<EventDTO> results = ticketmasterClient.searchEvents(request);

        // Sort by start time (earliest first) for travel planning relevance
        results = results.stream()
                .sorted(Comparator.comparing(
                        EventDTO::getStartTime,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .collect(Collectors.toList());

        log.info("Returning {} event results", results.size());
        return results;
    }
}
