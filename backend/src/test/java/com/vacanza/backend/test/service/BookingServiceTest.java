package com.vacanza.backend.test.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.dto.request.AccommodationSearchRequestDTO;
import com.vacanza.backend.dto.request.TransportSearchRequestDTO;
import com.vacanza.backend.dto.response.AccommodationOptionDTO;
import com.vacanza.backend.dto.response.DestinationSuggestionDTO;
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
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
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
@MockitoSettings(strictness = Strictness.LENIENT)
class BookingServiceTest {

    @Mock private SerpApiClient serpApiClient;
    @Mock private ApiCacheRepository cacheRepo;
    @Mock private ObjectMapper objectMapper;

    @InjectMocks private BookingServiceImpl bookingService;

    // ── Cache HIT ──────────────────────────────────────

    @Test
    @DisplayName("CACHE HIT: flights — SerpAPI not called")
    void cacheHit_flights() throws JsonProcessingException {
        TransportSearchRequestDTO req = flightReq();
        String json = "[]";
        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.FLIGHT), anyString(), any(Instant.class)))
                .thenReturn(Optional.of(cacheEntry(ApiCacheType.FLIGHT, json)));
        when(objectMapper.readValue(eq(json), any(TypeReference.class)))
                .thenReturn(List.of(TransportOptionDTO.builder().carrier("TK").price(new BigDecimal("200")).build()));

        List<TransportOptionDTO> r = bookingService.searchTransportation(req);

        assertThat(r).hasSize(1);
        verify(serpApiClient, never()).searchFlights(any());
    }

    @Test
    @DisplayName("CACHE HIT: hotels — SerpAPI not called")
    void cacheHit_hotels() throws JsonProcessingException {
        AccommodationSearchRequestDTO req = hotelReq();
        String json = "[]";
        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.HOTEL), anyString(), any(Instant.class)))
                .thenReturn(Optional.of(cacheEntry(ApiCacheType.HOTEL, json)));
        when(objectMapper.readValue(eq(json), any(TypeReference.class)))
                .thenReturn(List.of(AccommodationOptionDTO.builder().hotelName("Ritz").price(new BigDecimal("500")).build()));

        List<AccommodationOptionDTO> r = bookingService.searchAccommodations(req);

        assertThat(r).hasSize(1);
        verify(serpApiClient, never()).searchHotels(any());
    }

    @Test
    @DisplayName("CACHE HIT: airports — SerpAPI not called")
    void cacheHit_airports() throws JsonProcessingException {
        String json = "[]";
        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.AIRPORT), eq("istanbul"), any(Instant.class)))
                .thenReturn(Optional.of(cacheEntry(ApiCacheType.AIRPORT, json)));
        SerpApiAirportSuggestion s = new SerpApiAirportSuggestion();
        s.setIataCode("IST");
        when(objectMapper.readValue(eq(json), any(TypeReference.class)))
                .thenReturn(List.of(s));

        List<SerpApiAirportSuggestion> r = bookingService.searchAirports("Istanbul");

        assertThat(r).hasSize(1);
        verify(serpApiClient, never()).searchAirports(any());
    }

    // ── Cache MISS ──────────────────────────────────────

    @Test
    @DisplayName("CACHE MISS: flights — SerpAPI called, result saved")
    void cacheMiss_flights() throws JsonProcessingException {
        TransportSearchRequestDTO req = flightReq();
        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.FLIGHT), anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());
        when(serpApiClient.searchFlights(any())).thenReturn(List.of(
                TransportOptionDTO.builder().carrier("TK").price(new BigDecimal("200")).build()));
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");
        when(cacheRepo.findByCacheTypeAndCacheKey(eq(ApiCacheType.FLIGHT), anyString()))
                .thenReturn(Optional.empty());

        List<TransportOptionDTO> r = bookingService.searchTransportation(req);

        assertThat(r).hasSize(1);
        verify(serpApiClient).searchFlights(any());
        verify(cacheRepo).save(any(ApiCache.class));
    }

    @Test
    @DisplayName("CACHE MISS: flights with name resolution — Resolves to IATA, SerpAPI called")
    void cacheMiss_flights_resolution() throws JsonProcessingException {
        TransportSearchRequestDTO req = new TransportSearchRequestDTO();
        req.setOrigin("Istanbul"); req.setDestination("CDG");
        req.setDepartureDate(LocalDate.of(2025, 7, 1));
        req.setCurrency("USD"); req.setAdults(1);

        // 1) Resolving Istanbul -> IST via searchAirports cache miss
        lenient().when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.AIRPORT), eq("istanbul"), any(Instant.class)))
                .thenReturn(Optional.empty());
        SerpApiAirportSuggestion ist = new SerpApiAirportSuggestion();
        ist.setIataCode("IST");
        lenient().when(serpApiClient.searchAirports(anyString())).thenReturn(List.of(ist));
        lenient().when(objectMapper.writeValueAsString(any())).thenReturn("[]");
        lenient().when(cacheRepo.findByCacheTypeAndCacheKey(eq(ApiCacheType.AIRPORT), anyString()))
                .thenReturn(Optional.empty());

        // 2) Flight search cache miss (key: IST_CDG_...)
        lenient().when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.FLIGHT), anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());
        lenient().when(serpApiClient.searchFlights(argThat(r -> "IST".equals(r.getOrigin())))).thenReturn(List.of(
                TransportOptionDTO.builder().carrier("TK").price(new BigDecimal("200")).build()));
        lenient().when(cacheRepo.findByCacheTypeAndCacheKey(eq(ApiCacheType.FLIGHT), anyString()))
                .thenReturn(Optional.empty());

        List<TransportOptionDTO> r = bookingService.searchTransportation(req);

        assertThat(r).hasSize(1);
        verify(serpApiClient).searchAirports("Istanbul");
        verify(serpApiClient).searchFlights(argThat(flightReq -> "IST".equals(flightReq.getOrigin())));
        verify(cacheRepo, times(2)).save(any(ApiCache.class));
    }

    @Test
    @DisplayName("CACHE MISS: hotels — SerpAPI called, result saved")
    void cacheMiss_hotels() throws JsonProcessingException {
        AccommodationSearchRequestDTO req = hotelReq();
        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.HOTEL), anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());
        when(serpApiClient.searchHotels(any())).thenReturn(List.of(
                AccommodationOptionDTO.builder().hotelName("Ritz").price(new BigDecimal("500")).build()));
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");
        when(cacheRepo.findByCacheTypeAndCacheKey(eq(ApiCacheType.HOTEL), anyString()))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> r = bookingService.searchAccommodations(req);

        assertThat(r).hasSize(1);
        verify(serpApiClient).searchHotels(any());
        verify(cacheRepo).save(any(ApiCache.class));
    }

    @Test
    @DisplayName("CACHE MISS: airport — SerpAPI called, result saved with 30d TTL")
    void cacheMiss_airports() throws JsonProcessingException {
        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.AIRPORT), eq("istanbul"), any(Instant.class)))
                .thenReturn(Optional.empty());
        SerpApiAirportSuggestion ist = new SerpApiAirportSuggestion();
        ist.setIataCode("IST"); ist.setCity("Istanbul"); ist.setCountry("Turkey");
        when(serpApiClient.searchAirports(anyString())).thenReturn(List.of(ist));
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");
        when(cacheRepo.findByCacheTypeAndCacheKey(eq(ApiCacheType.AIRPORT), eq("istanbul")))
                .thenReturn(Optional.empty());

        List<SerpApiAirportSuggestion> r = bookingService.searchAirports("istanbul");

        assertThat(r).hasSize(1);
        verify(cacheRepo).save(any(ApiCache.class));
    }

    // ── Empty results NOT cached ────────────────────────

    @Test
    @DisplayName("Empty flight results should NOT be cached")
    void emptyFlights_notCached() {
        TransportSearchRequestDTO req = flightReq();
        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.FLIGHT), anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());
        when(serpApiClient.searchFlights(any())).thenReturn(Collections.emptyList());

        assertThat(bookingService.searchTransportation(req)).isEmpty();
        verify(cacheRepo, never()).save(any());
    }

    @Test
    @DisplayName("Empty hotel results should NOT be cached")
    void emptyHotels_notCached() {
        AccommodationSearchRequestDTO req = hotelReq();
        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.HOTEL), anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());
        when(serpApiClient.searchHotels(any())).thenReturn(Collections.emptyList());

        assertThat(bookingService.searchAccommodations(req)).isEmpty();
        verify(cacheRepo, never()).save(any());
    }

    // ── Destination autocomplete (zero SerpAPI cost) ────

    @Test
    @DisplayName("searchDestinations is disabled — returns empty list")
    void destinations_disabled() {
        List<DestinationSuggestionDTO> r = bookingService.searchDestinations("Istanbul");
        assertThat(r).isEmpty();
        verify(serpApiClient, never()).searchAirports(any());
    }

    // ── Budget filtering ────────────────────────────────

    @Test
    @DisplayName("Flights over budget are filtered out")
    void budgetFilter() throws JsonProcessingException {
        TransportSearchRequestDTO req = flightReq();
        req.setBudget(new BigDecimal("250"));
        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.FLIGHT), anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());
        when(serpApiClient.searchFlights(any())).thenReturn(List.of(
                TransportOptionDTO.builder().carrier("TK").price(new BigDecimal("200")).build(),
                TransportOptionDTO.builder().carrier("AF").price(new BigDecimal("400")).build()));
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");
        when(cacheRepo.findByCacheTypeAndCacheKey(eq(ApiCacheType.FLIGHT), anyString()))
                .thenReturn(Optional.empty());

        List<TransportOptionDTO> r = bookingService.searchTransportation(req);

        assertThat(r).hasSize(1);
        assertThat(r.get(0).getCarrier()).isEqualTo("TK");
    }

    // ── Sorting ─────────────────────────────────────────

    @Test
    @DisplayName("Hotels sorted by PRICE_ASC")
    void sort_priceAsc() throws JsonProcessingException {
        AccommodationSearchRequestDTO req = hotelReq();
        req.setSortBy(SortCriteria.PRICE_ASC);
        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.HOTEL), anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());
        when(serpApiClient.searchHotels(any())).thenReturn(List.of(
                AccommodationOptionDTO.builder().hotelName("X").price(new BigDecimal("300")).build(),
                AccommodationOptionDTO.builder().hotelName("Y").price(new BigDecimal("50")).build()));
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");
        when(cacheRepo.findByCacheTypeAndCacheKey(eq(ApiCacheType.HOTEL), anyString()))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> r = bookingService.searchAccommodations(req);

        assertThat(r.get(0).getPrice()).isEqualByComparingTo("50");
        assertThat(r.get(1).getPrice()).isEqualByComparingTo("300");
    }

    @Test
    @DisplayName("Hotels sorted by RATING_DESC")
    void sort_ratingDesc() throws JsonProcessingException {
        AccommodationSearchRequestDTO req = hotelReq();
        req.setSortBy(SortCriteria.RATING_DESC);
        when(cacheRepo.findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                eq(ApiCacheType.HOTEL), anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());
        when(serpApiClient.searchHotels(any())).thenReturn(List.of(
                AccommodationOptionDTO.builder().hotelName("Low").rating(2.5).build(),
                AccommodationOptionDTO.builder().hotelName("High").rating(4.8).build()));
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");
        when(cacheRepo.findByCacheTypeAndCacheKey(eq(ApiCacheType.HOTEL), anyString()))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> r = bookingService.searchAccommodations(req);

        assertThat(r.get(0).getRating()).isEqualTo(4.8);
    }

    // ── Validation ──────────────────────────────────────

    @Test
    @DisplayName("Blank airport query throws BookingException")
    void blankAirportQuery() {
        assertThatThrownBy(() -> bookingService.searchAirports("   "))
                .isInstanceOf(BookingException.class);
    }

    @Test
    @DisplayName("searchDestinations returns empty list even for blank query (no exception)")
    void blankDestinationQuery() {
        List<DestinationSuggestionDTO> r = bookingService.searchDestinations("  ");
        assertThat(r).isEmpty();
    }

    // ── Helpers ─────────────────────────────────────────

    private TransportSearchRequestDTO flightReq() {
        TransportSearchRequestDTO r = new TransportSearchRequestDTO();
        r.setOrigin("IST"); r.setDestination("CDG");
        r.setDepartureDate(LocalDate.of(2025, 7, 1));
        r.setCurrency("USD"); r.setAdults(1);
        return r;
    }

    private AccommodationSearchRequestDTO hotelReq() {
        AccommodationSearchRequestDTO r = new AccommodationSearchRequestDTO();
        r.setQuery("Hotels in Paris");
        r.setCheckInDate(LocalDate.of(2025, 7, 1));
        r.setCheckOutDate(LocalDate.of(2025, 7, 5));
        r.setCurrency("USD"); r.setAdults(1);
        return r;
    }

    private ApiCache cacheEntry(ApiCacheType type, String json) {
        return ApiCache.builder()
                .cacheType(type).cacheKey("test-key").resultsJson(json)
                .cachedAt(Instant.now().minusSeconds(60))
                .expiresAt(Instant.now().plusSeconds(60000))
                .build();
    }
}
