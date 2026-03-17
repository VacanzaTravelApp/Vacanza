package com.vacanza.backend.test.service;

import com.vacanza.backend.dto.request.EventSearchRequestDTO;
import com.vacanza.backend.dto.response.EventDTO;
import com.vacanza.backend.integration.event.TicketmasterClient;
import com.vacanza.backend.service.impl.EventServiceImpl;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EventServiceTest {

    @Mock
    private TicketmasterClient ticketmasterClient;

    @InjectMocks
    private EventServiceImpl eventService;

    @Test
    @DisplayName("Should return empty list when API client returns empty")
    void shouldReturnEmpty_WhenApiReturnsEmpty() {
        EventSearchRequestDTO request = new EventSearchRequestDTO();
        request.setCity("Unknown City");

        when(ticketmasterClient.searchEvents(any())).thenReturn(Collections.emptyList());

        List<EventDTO> results = eventService.searchEvents(request);

        assertThat(results).isEmpty();
    }

    @Test
    @DisplayName("Should sort events by start time ascending (earliest first)")
    void shouldSortEvents_ByStartTimeAsc() {
        EventSearchRequestDTO request = new EventSearchRequestDTO();
        request.setCity("Istanbul");

        List<EventDTO> mockResults = List.of(
                EventDTO.builder().name("Event C").startTime("2026-05-10T20:00:00Z").build(),
                EventDTO.builder().name("Event A").startTime("2026-04-01T19:00:00Z").build(),
                EventDTO.builder().name("Event B").startTime("2026-04-15T21:00:00Z").build());

        when(ticketmasterClient.searchEvents(any())).thenReturn(mockResults);

        List<EventDTO> results = eventService.searchEvents(request);

        assertThat(results).hasSize(3);
        assertThat(results).extracting(EventDTO::getName)
                .containsExactly("Event A", "Event B", "Event C");
    }

    @Test
    @DisplayName("Should handle missing start times by pushing them to the end (nulls last)")
    void shouldSortEvents_WithMissingStartTime_NullLast() {
        EventSearchRequestDTO request = new EventSearchRequestDTO();
        request.setCity("Paris");

        List<EventDTO> mockResults = List.of(
                EventDTO.builder().name("No Date Event").startTime(null).build(),
                EventDTO.builder().name("Dated Event").startTime("2026-04-01T19:00:00Z").build());

        when(ticketmasterClient.searchEvents(any())).thenReturn(mockResults);

        List<EventDTO> results = eventService.searchEvents(request);

        assertThat(results).hasSize(2);
        assertThat(results).extracting(EventDTO::getName)
                .containsExactly("Dated Event", "No Date Event");
    }
}
