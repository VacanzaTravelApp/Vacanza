package com.vacanza.backend.test.service;

import com.vacanza.backend.dto.request.AccommodationSearchRequestDTO;
import com.vacanza.backend.dto.request.TransportSearchRequestDTO;
import com.vacanza.backend.dto.response.AccommodationOptionDTO;
import com.vacanza.backend.dto.response.TransportOptionDTO;
import com.vacanza.backend.entity.enums.SortCriteria;
import com.vacanza.backend.integration.booking.AmadeusClient;
import com.vacanza.backend.service.impl.BookingServiceImpl;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BookingServiceTest {

    @Mock
    private AmadeusClient amadeusClient;

    @InjectMocks
    private BookingServiceImpl bookingService;

    // ──────────────────────────────────────────────────────────────
    // Budget filtering
    // ──────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Should filter out accommodations exceeding budget")
    void shouldFilterAccommodations_ExceedingBudget() {
        AccommodationSearchRequestDTO request = new AccommodationSearchRequestDTO();
        request.setCityCode("PAR");
        request.setCheckInDate(LocalDate.of(2025, 7, 1));
        request.setCheckOutDate(LocalDate.of(2025, 7, 5));
        request.setBudget(new BigDecimal("150.00"));

        List<AccommodationOptionDTO> mockResults = List.of(
                AccommodationOptionDTO.builder().hotelName("Cheap Hotel").price(new BigDecimal("100.00")).build(),
                AccommodationOptionDTO.builder().hotelName("Mid Hotel").price(new BigDecimal("150.00")).build(),
                AccommodationOptionDTO.builder().hotelName("Expensive Hotel").price(new BigDecimal("300.00")).build());

        when(amadeusClient.searchHotels(any())).thenReturn(mockResults);

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).hasSize(2);
        assertThat(results).extracting(AccommodationOptionDTO::getHotelName)
                .containsExactlyInAnyOrder("Cheap Hotel", "Mid Hotel");
    }

    @Test
    @DisplayName("Should filter out flights exceeding budget")
    void shouldFilterFlights_ExceedingBudget() {
        TransportSearchRequestDTO request = new TransportSearchRequestDTO();
        request.setOrigin("IST");
        request.setDestination("PAR");
        request.setDepartureDate(LocalDate.of(2025, 7, 1));
        request.setBudget(new BigDecimal("250.00"));

        List<TransportOptionDTO> mockResults = List.of(
                TransportOptionDTO.builder().carrier("TK").price(new BigDecimal("200.00")).build(),
                TransportOptionDTO.builder().carrier("AF").price(new BigDecimal("400.00")).build(),
                TransportOptionDTO.builder().carrier("PC").price(new BigDecimal("150.00")).build());

        when(amadeusClient.searchFlights(any())).thenReturn(mockResults);

        List<TransportOptionDTO> results = bookingService.searchTransportation(request);

        assertThat(results).hasSize(2);
        assertThat(results).extracting(TransportOptionDTO::getCarrier)
                .containsExactlyInAnyOrder("TK", "PC");
    }

    @Test
    @DisplayName("Should return all results when budget is null")
    void shouldReturnAll_WhenBudgetIsNull() {
        AccommodationSearchRequestDTO request = new AccommodationSearchRequestDTO();
        request.setCityCode("PAR");
        request.setCheckInDate(LocalDate.of(2025, 7, 1));
        request.setCheckOutDate(LocalDate.of(2025, 7, 5));
        request.setBudget(null);

        List<AccommodationOptionDTO> mockResults = List.of(
                AccommodationOptionDTO.builder().hotelName("A").price(new BigDecimal("100.00")).build(),
                AccommodationOptionDTO.builder().hotelName("B").price(new BigDecimal("500.00")).build());

        when(amadeusClient.searchHotels(any())).thenReturn(mockResults);

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).hasSize(2);
    }

    // ──────────────────────────────────────────────────────────────
    // Sorting
    // ──────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Should sort accommodations by PRICE_ASC")
    void shouldSortAccommodations_PriceAsc() {
        AccommodationSearchRequestDTO request = new AccommodationSearchRequestDTO();
        request.setCityCode("PAR");
        request.setCheckInDate(LocalDate.of(2025, 7, 1));
        request.setCheckOutDate(LocalDate.of(2025, 7, 5));
        request.setSortBy(SortCriteria.PRICE_ASC);

        List<AccommodationOptionDTO> mockResults = List.of(
                AccommodationOptionDTO.builder().hotelName("Expensive").price(new BigDecimal("300.00")).build(),
                AccommodationOptionDTO.builder().hotelName("Cheap").price(new BigDecimal("50.00")).build(),
                AccommodationOptionDTO.builder().hotelName("Mid").price(new BigDecimal("150.00")).build());

        when(amadeusClient.searchHotels(any())).thenReturn(mockResults);

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).extracting(AccommodationOptionDTO::getPrice)
                .containsExactly(
                        new BigDecimal("50.00"),
                        new BigDecimal("150.00"),
                        new BigDecimal("300.00"));
    }

    @Test
    @DisplayName("Should sort accommodations by PRICE_DESC")
    void shouldSortAccommodations_PriceDesc() {
        AccommodationSearchRequestDTO request = new AccommodationSearchRequestDTO();
        request.setCityCode("PAR");
        request.setCheckInDate(LocalDate.of(2025, 7, 1));
        request.setCheckOutDate(LocalDate.of(2025, 7, 5));
        request.setSortBy(SortCriteria.PRICE_DESC);

        List<AccommodationOptionDTO> mockResults = List.of(
                AccommodationOptionDTO.builder().hotelName("Cheap").price(new BigDecimal("50.00")).build(),
                AccommodationOptionDTO.builder().hotelName("Expensive").price(new BigDecimal("300.00")).build());

        when(amadeusClient.searchHotels(any())).thenReturn(mockResults);

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).extracting(AccommodationOptionDTO::getPrice)
                .containsExactly(new BigDecimal("300.00"), new BigDecimal("50.00"));
    }

    @Test
    @DisplayName("Should sort accommodations by RATING_DESC")
    void shouldSortAccommodations_RatingDesc() {
        AccommodationSearchRequestDTO request = new AccommodationSearchRequestDTO();
        request.setCityCode("PAR");
        request.setCheckInDate(LocalDate.of(2025, 7, 1));
        request.setCheckOutDate(LocalDate.of(2025, 7, 5));
        request.setSortBy(SortCriteria.RATING_DESC);

        List<AccommodationOptionDTO> mockResults = List.of(
                AccommodationOptionDTO.builder().hotelName("Low").rating(2.5).build(),
                AccommodationOptionDTO.builder().hotelName("High").rating(4.8).build(),
                AccommodationOptionDTO.builder().hotelName("Mid").rating(3.5).build());

        when(amadeusClient.searchHotels(any())).thenReturn(mockResults);

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).extracting(AccommodationOptionDTO::getRating)
                .containsExactly(4.8, 3.5, 2.5);
    }

    // ──────────────────────────────────────────────────────────────
    // API failure handling
    // ──────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Should return empty list when API client returns empty")
    void shouldReturnEmpty_WhenApiReturnsEmpty() {
        AccommodationSearchRequestDTO request = new AccommodationSearchRequestDTO();
        request.setCityCode("XXX");
        request.setCheckInDate(LocalDate.of(2025, 7, 1));
        request.setCheckOutDate(LocalDate.of(2025, 7, 5));

        when(amadeusClient.searchHotels(any())).thenReturn(Collections.emptyList());

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).isEmpty();
    }

    @Test
    @DisplayName("Should return empty list when flight API returns empty")
    void shouldReturnEmpty_WhenFlightApiReturnsEmpty() {
        TransportSearchRequestDTO request = new TransportSearchRequestDTO();
        request.setOrigin("IST");
        request.setDestination("XXX");
        request.setDepartureDate(LocalDate.of(2025, 7, 1));

        when(amadeusClient.searchFlights(any())).thenReturn(Collections.emptyList());

        List<TransportOptionDTO> results = bookingService.searchTransportation(request);

        assertThat(results).isEmpty();
    }
}
