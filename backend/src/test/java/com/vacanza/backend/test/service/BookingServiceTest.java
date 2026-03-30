package com.vacanza.backend.test.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.dto.request.AccommodationSearchRequestDTO;
import com.vacanza.backend.dto.request.TransportSearchRequestDTO;
import com.vacanza.backend.dto.response.AccommodationOptionDTO;
import com.vacanza.backend.dto.response.TransportOptionDTO;
import com.vacanza.backend.entity.cache.ApiCache;
import com.vacanza.backend.entity.cache.ApiCacheType;
import com.vacanza.backend.entity.enums.SortCriteria;
import com.vacanza.backend.exceptions.BookingException;
import com.vacanza.backend.integration.booking.SerpApiAirportSuggestion;
import com.vacanza.backend.integration.booking.SerpApiClient;
import com.vacanza.backend.repo.ApiCacheRepository;
import com.vacanza.backend.service.impl.BookingServiceImpl;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BookingServiceTest {

    @Mock private SerpApiClient serpApiClient;
    @Mock private ApiCacheRepository cacheRepo;
    @Mock private ObjectMapper objectMapper;

    @InjectMocks
    private BookingServiceImpl bookingService;

    // ──────────────────────────────────────────────
    // Cache HIT — SerpAPI must NOT be called
    // ──────────────────────────────────────────────

    @Test
    @DisplayName("CACHE HIT: should return cached flights without calling SerpAPI")
    void shouldReturnCachedFlights_WhenCacheHit() throws JsonProcessingException {
        TransportSearchRequestDTO request = flightRequest();

        String json = "[{\"carrier\":\"TK\",\"price\":200}]";
        ApiCache hit = ApiCache.builder()
                .cacheType(ApiCacheType.FLIGHT)
                .cacheKey("IST_CDG_2025-07-01_OW_1_USD")
                .resultsJson(json)
                .cachedAt(Instant.now().minusSeconds(3600))
                .expiresAt(Instant.now().plusSeconds(18000))
                .build();

        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.FLIGHT), anyString(), any(Instant.class)))
                .thenReturn(Optional.of(hit));

        List<TransportOptionDTO> deserialized = List.of(
                TransportOptionDTO.builder().carrier("TK").price(new BigDecimal("200")).build());
        when(objectMapper.readValue(eq(json), any(TypeReference.class)))
                .thenReturn(deserialized);

        List<TransportOptionDTO> results = bookingService.searchTransportation(request);

        assertThat(results).hasSize(1);
        assertThat(results.get(0).getCarrier()).isEqualTo("TK");
        verify(serpApiClient, never()).searchFlights(any());
    }

    @Test
    @DisplayName("CACHE HIT: should return cached hotels without calling SerpAPI")
    void shouldReturnCachedHotels_WhenCacheHit() throws JsonProcessingException {
        AccommodationSearchRequestDTO request = hotelRequest();

        String json = "[{\"hotelName\":\"Ritz\",\"price\":500}]";
        ApiCache hit = ApiCache.builder()
                .cacheType(ApiCacheType.HOTEL)
                .cacheKey("hotels-in-paris_2025-07-01_2025-07-05_1_USD_any")
                .resultsJson(json)
                .cachedAt(Instant.now().minusSeconds(3600))
                .expiresAt(Instant.now().plusSeconds(40000))
                .build();

        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.HOTEL), anyString(), any(Instant.class)))
                .thenReturn(Optional.of(hit));

        List<AccommodationOptionDTO> deserialized = List.of(
                AccommodationOptionDTO.builder().hotelName("Ritz").price(new BigDecimal("500")).build());
        when(objectMapper.readValue(eq(json), any(TypeReference.class)))
                .thenReturn(deserialized);

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).hasSize(1);
        assertThat(results.get(0).getHotelName()).isEqualTo("Ritz");
        verify(serpApiClient, never()).searchHotels(any());
    }

    @Test
    @DisplayName("CACHE HIT: should return cached airport suggestions without calling SerpAPI")
    void shouldReturnCachedAirports_WhenCacheHit() throws JsonProcessingException {
        String json = "[{\"iataCode\":\"IST\"}]";
        ApiCache hit = ApiCache.builder()
                .cacheType(ApiCacheType.AIRPORT)
                .cacheKey("istanbul")
                .resultsJson(json)
                .cachedAt(Instant.now().minusSeconds(3600))
                .expiresAt(Instant.now().plusSeconds(600000))
                .build();

        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.AIRPORT), eq("istanbul"), any(Instant.class)))
                .thenReturn(Optional.of(hit));

        SerpApiAirportSuggestion s = new SerpApiAirportSuggestion();
        s.setIataCode("IST");
        when(objectMapper.readValue(eq(json), any(TypeReference.class)))
                .thenReturn(List.of(s));

        List<SerpApiAirportSuggestion> results = bookingService.searchAirports("Istanbul");

        assertThat(results).hasSize(1);
        assertThat(results.get(0).getIataCode()).isEqualTo("IST");
        verify(serpApiClient, never()).searchAirports(any());
    }

    // ──────────────────────────────────────────────
    // Cache MISS — SerpAPI called, result saved
    // ──────────────────────────────────────────────

    @Test
    @DisplayName("CACHE MISS: should call SerpAPI and save flight results to DB")
    void shouldCallSerpApiAndSave_WhenFlightCacheMiss() throws JsonProcessingException {
        TransportSearchRequestDTO request = flightRequest();

        // Cache miss
        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.FLIGHT), anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());

        List<TransportOptionDTO> apiResults = List.of(
                TransportOptionDTO.builder().carrier("TK").price(new BigDecimal("200")).build());
        when(serpApiClient.searchFlights(any())).thenReturn(apiResults);
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");

        // Upsert: no existing row
        when(cacheRepo.findByCacheTypeAndCacheKey(eq(ApiCacheType.FLIGHT), anyString()))
                .thenReturn(Optional.empty());

        List<TransportOptionDTO> results = bookingService.searchTransportation(request);

        assertThat(results).hasSize(1);
        verify(serpApiClient, times(1)).searchFlights(any());
        verify(cacheRepo, times(1)).save(any(ApiCache.class));
    }

    @Test
    @DisplayName("CACHE MISS: should call SerpAPI and save hotel results to DB")
    void shouldCallSerpApiAndSave_WhenHotelCacheMiss() throws JsonProcessingException {
        AccommodationSearchRequestDTO request = hotelRequest();

        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.HOTEL), anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> apiResults = List.of(
                AccommodationOptionDTO.builder().hotelName("Ritz").price(new BigDecimal("500")).build());
        when(serpApiClient.searchHotels(any())).thenReturn(apiResults);
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");

        when(cacheRepo.findByCacheTypeAndCacheKey(eq(ApiCacheType.HOTEL), anyString()))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).hasSize(1);
        verify(serpApiClient, times(1)).searchHotels(any());
        verify(cacheRepo, times(1)).save(any(ApiCache.class));
    }

    @Test
    @DisplayName("CACHE MISS: should save airport results with 30-day TTL")
    void shouldSaveAirportResults_WithLongTTL() throws JsonProcessingException {
        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.AIRPORT), eq("istanbul"), any(Instant.class)))
                .thenReturn(Optional.empty());

        SerpApiAirportSuggestion ist = new SerpApiAirportSuggestion();
        ist.setIataCode("IST");
        ist.setName("Istanbul Airport");
        ist.setCity("Istanbul");
        ist.setCountry("Turkey");

        when(serpApiClient.searchAirports("istanbul")).thenReturn(List.of(ist));
        when(objectMapper.writeValueAsString(any())).thenReturn("[{\"iataCode\":\"IST\"}]");
        when(cacheRepo.findByCacheTypeAndCacheKey(eq(ApiCacheType.AIRPORT), eq("istanbul")))
                .thenReturn(Optional.empty());

        List<SerpApiAirportSuggestion> results = bookingService.searchAirports("istanbul");

        assertThat(results).hasSize(1);
        assertThat(results.get(0).getIataCode()).isEqualTo("IST");
        verify(cacheRepo).save(any(ApiCache.class));
    }

    // ──────────────────────────────────────────────
    // Empty results must NOT be cached
    // ──────────────────────────────────────────────

    @Test
    @DisplayName("Should NOT cache empty flight results")
    void shouldNotCacheEmptyFlightResults() {
        TransportSearchRequestDTO request = flightRequest();

        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.FLIGHT), anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());
        when(serpApiClient.searchFlights(any())).thenReturn(Collections.emptyList());

        List<TransportOptionDTO> results = bookingService.searchTransportation(request);

        assertThat(results).isEmpty();
        verify(cacheRepo, never()).save(any());
    }

    @Test
    @DisplayName("Should NOT cache empty hotel results")
    void shouldNotCacheEmptyHotelResults() {
        AccommodationSearchRequestDTO request = hotelRequest();

        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.HOTEL), anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());
        when(serpApiClient.searchHotels(any())).thenReturn(Collections.emptyList());

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).isEmpty();
        verify(cacheRepo, never()).save(any());
    }

    // ──────────────────────────────────────────────
    // Budget filtering (post-cache)
    // ──────────────────────────────────────────────

    @Test
    @DisplayName("Should filter out flights exceeding budget (cache miss path)")
    void shouldFilterFlights_ExceedingBudget() throws JsonProcessingException {
        TransportSearchRequestDTO request = flightRequest();
        request.setBudget(new BigDecimal("250.00"));

        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.FLIGHT), anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());

        List<TransportOptionDTO> mockResults = List.of(
                TransportOptionDTO.builder().carrier("TK").price(new BigDecimal("200.00")).build(),
                TransportOptionDTO.builder().carrier("AF").price(new BigDecimal("400.00")).build(),
                TransportOptionDTO.builder().carrier("PC").price(new BigDecimal("150.00")).build());

        when(serpApiClient.searchFlights(any())).thenReturn(mockResults);
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");
        when(cacheRepo.findByCacheTypeAndCacheKey(eq(ApiCacheType.FLIGHT), anyString()))
                .thenReturn(Optional.empty());

        List<TransportOptionDTO> results = bookingService.searchTransportation(request);

        assertThat(results).hasSize(2);
        assertThat(results).extracting(TransportOptionDTO::getCarrier)
                .containsExactlyInAnyOrder("TK", "PC");
    }

    // ──────────────────────────────────────────────
    // Sorting
    // ──────────────────────────────────────────────

    @Test
    @DisplayName("Should sort accommodations by PRICE_ASC")
    void shouldSortAccommodations_PriceAsc() throws JsonProcessingException {
        AccommodationSearchRequestDTO request = hotelRequest();
        request.setSortBy(SortCriteria.PRICE_ASC);

        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.HOTEL), anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> mockResults = List.of(
                AccommodationOptionDTO.builder().hotelName("Expensive").price(new BigDecimal("300.00")).build(),
                AccommodationOptionDTO.builder().hotelName("Cheap").price(new BigDecimal("50.00")).build(),
                AccommodationOptionDTO.builder().hotelName("Mid").price(new BigDecimal("150.00")).build());

        when(serpApiClient.searchHotels(any())).thenReturn(mockResults);
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");
        when(cacheRepo.findByCacheTypeAndCacheKey(eq(ApiCacheType.HOTEL), anyString()))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).extracting(AccommodationOptionDTO::getPrice)
                .containsExactly(
                        new BigDecimal("50.00"),
                        new BigDecimal("150.00"),
                        new BigDecimal("300.00"));
    }

    @Test
    @DisplayName("Should sort accommodations by RATING_DESC")
    void shouldSortAccommodations_RatingDesc() throws JsonProcessingException {
        AccommodationSearchRequestDTO request = hotelRequest();
        request.setSortBy(SortCriteria.RATING_DESC);

        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.HOTEL), anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> mockResults = List.of(
                AccommodationOptionDTO.builder().hotelName("Low").rating(2.5).build(),
                AccommodationOptionDTO.builder().hotelName("High").rating(4.8).build(),
                AccommodationOptionDTO.builder().hotelName("Mid").rating(3.5).build());

        when(serpApiClient.searchHotels(any())).thenReturn(mockResults);
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");
        when(cacheRepo.findByCacheTypeAndCacheKey(eq(ApiCacheType.HOTEL), anyString()))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).extracting(AccommodationOptionDTO::getRating)
                .containsExactly(4.8, 3.5, 2.5);
    }

    // ──────────────────────────────────────────────
    // Validation
    // ──────────────────────────────────────────────

    @Test
    @DisplayName("Should throw BookingException when airport query is blank")
    void searchAirports_BlankQuery_ThrowsException() {
        assertThatThrownBy(() -> bookingService.searchAirports("   "))
                .isInstanceOf(BookingException.class)
                .hasMessageContaining("must not be blank");
    }

    // ──────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────

    private TransportSearchRequestDTO flightRequest() {
        TransportSearchRequestDTO r = new TransportSearchRequestDTO();
        r.setOrigin("IST");
        r.setDestination("CDG");
        r.setDepartureDate(LocalDate.of(2025, 7, 1));
        r.setCurrency("USD");
        r.setAdults(1);
        return r;
    }

    private AccommodationSearchRequestDTO hotelRequest() {
        AccommodationSearchRequestDTO r = new AccommodationSearchRequestDTO();
        r.setQuery("Hotels in Paris");
        r.setCheckInDate(LocalDate.of(2025, 7, 1));
        r.setCheckOutDate(LocalDate.of(2025, 7, 5));
        r.setCurrency("USD");
        r.setAdults(1);
        return r;
    }
}
