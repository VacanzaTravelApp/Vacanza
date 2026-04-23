package com.vacanza.backend.test.service;

import com.vacanza.backend.dto.request.EventSearchRequestDTO;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.service.EventRecommendationService;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

class EventRecommendationServiceDateRangeTest {

    @Test
    void tripDatesUserSpecified_false_usesThirtyDayBroadWindow() {
        EventSearchRequestDTO request = new EventSearchRequestDTO();
        AiChatDto.RouteData routeData = new AiChatDto.RouteData();
        routeData.setTripDatesUserSpecified(false);

        LocalDate tripStart = LocalDate.of(2026, 4, 10);
        EventRecommendationService.applyTicketmasterDateRange(request, routeData, null, tripStart, 3);

        assertThat(request.getStartDate()).isNotNull();
        assertThat(request.getEndDate()).isNotNull();
        assertThat(request.getEndDate().toEpochDay() - request.getStartDate().toEpochDay())
                .isEqualTo(29);
    }

    @Test
    void tripDatesUserSpecified_true_usesTripWindow() {
        EventSearchRequestDTO request = new EventSearchRequestDTO();
        AiChatDto.RouteData routeData = new AiChatDto.RouteData();
        routeData.setTripDatesUserSpecified(true);

        LocalDate tripStart = LocalDate.of(2026, 4, 5);
        EventRecommendationService.applyTicketmasterDateRange(request, routeData, null, tripStart, 3);

        assertThat(request.getStartDate()).isEqualTo(tripStart);
        assertThat(request.getEndDate()).isEqualTo(LocalDate.of(2026, 4, 7));
    }

    @Test
    void legacyNull_usesBroadWindowLikeAbsentFlag() {
        EventSearchRequestDTO request = new EventSearchRequestDTO();
        LocalDate tripStart = LocalDate.of(2026, 4, 5);
        EventRecommendationService.applyTicketmasterDateRange(request, null, null, tripStart, 2);

        assertThat(request.getEndDate().toEpochDay() - request.getStartDate().toEpochDay()).isEqualTo(29);
    }
}
