package com.vacanza.backend.test.service;

import com.vacanza.backend.dto.request.EventSearchRequestDTO;
import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.service.EventRecommendationService;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class EventRecommendationTripStartTest {

    @Test
    void resolveTripStart_prefersTripStartDateOverGeneratedAt() {
        AiChatDto.RouteData rd = new AiChatDto.RouteData();
        rd.setTripStartDate("2026-06-20");

        AiRoute route = AiRoute.builder()
                .generatedAt(LocalDateTime.of(2026, 4, 5, 12, 0))
                .build();

        assertThat(EventRecommendationService.resolveTripStartLocalDate(rd, route))
                .isEqualTo(LocalDate.of(2026, 6, 20));
    }

    @Test
    void applyTicketmasterDateRange_tripStartDateOnly_narrowWindow() {
        EventSearchRequestDTO request = new EventSearchRequestDTO();
        AiChatDto.RouteData rd = new AiChatDto.RouteData();
        rd.setTripStartDate("2026-06-20");
        rd.setTripDatesUserSpecified(null);

        LocalDate tripStart = LocalDate.of(2026, 6, 20);
        EventRecommendationService.applyTicketmasterDateRange(request, rd, null, tripStart, 2);

        assertThat(request.getStartDate()).isEqualTo(LocalDate.of(2026, 6, 20));
        assertThat(request.getEndDate()).isEqualTo(LocalDate.of(2026, 6, 21));
    }
}
