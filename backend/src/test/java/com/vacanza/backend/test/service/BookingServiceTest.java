package com.vacanza.backend.test.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.dto.request.AccommodationSearchRequestDTO;
import com.vacanza.backend.dto.request.TransportSearchRequestDTO;
import com.vacanza.backend.dto.response.AccommodationOptionDTO;
import com.vacanza.backend.dto.response.TransportOptionDTO;
import com.vacanza.backend.entity.cache.AirportAutocompleteCache;
import com.vacanza.backend.entity.cache.FlightSearchCache;
import com.vacanza.backend.entity.cache.HotelSearchCache;
import com.vacanza.backend.entity.enums.SortCriteria;
import com.vacanza.backend.exceptions.BookingException;
import com.vacanza.backend.integration.booking.SerpApiAirportSuggestion;
import com.vacanza.backend.integration.booking.SerpApiClient;
import com.vacanza.backend.repo.AirportAutocompleteCacheRepository;
import com.vacanza.backend.repo.FlightSearchCacheRepository;
import com.vacanza.backend.repo.HotelSearchCacheRepository;
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
    @Mock private ObjectMapper objectMapper;
    @Mock private FlightSearchCacheRepository flightCacheRepo;
    @Mock private HotelSearchCacheRepository hotelCacheRepo;
    @Mock private AirportAutocompleteCacheRepository airportCacheRepo;

    @InjectMocks
    private BookingServiceImpl bookingService;

    // ──────────────────────────────────────────────────────────────
    // Cache HIT — SerpAPI must NOT be called
    // ──────────────────────────────────────────────────────────────

    @Test
    @DisplayName("CACHE HIT: should return cached flights without calling SerpAPI")
    void shouldReturnCachedFlights_WhenCacheHit() throws JsonProcessingException {
        TransportSearchRequestDTO request = flightRequest();

        String cachedJson = "[{\"carrier\":\"TK\",\"price\":200}]";
        FlightSearchCache hit = FlightSearchCache.builder()
                .cacheKey("IST_CDG_2025-07-01_OW_1_USD")
                .resultsJson(cachedJson)
                .cachedAt(Instant.now().minusSeconds(3600))
                .expiresAt(Instant.now().plusSeconds(18000))
                .build();

        when(flightCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), any(Instant.class)))
                .thenReturn(Optional.of(hit));

        List<TransportOptionDTO> deserialized = List.of(
                TransportOptionDTO.builder().carrier("TK").price(new BigDecimal("200")).build());
        when(objectMapper.readValue(eq(cachedJson), any(com.fasterxml.jackson.core.type.TypeReference.class)))
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

        String cachedJson = "[{\"hotelName\":\"Ritz\",\"price\":500}]";
        HotelSearchCache hit = HotelSearchCache.builder()
                .cacheKey("paris_2025-07-01_2025-07-05_1_USD_any")
                .resultsJson(cachedJson)
                .cachedAt(Instant.now().minusSeconds(3600))
                .expiresAt(Instant.now().plusSeconds(40000))
                .build();

        when(hotelCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), any(Instant.class)))
                .thenReturn(Optional.of(hit));

        List<AccommodationOptionDTO> deserialized = List.of(
                AccommodationOptionDTO.builder().hotelName("Ritz").price(new BigDecimal("500")).build());
        when(objectMapper.readValue(eq(cachedJson), any(com.fasterxml.jackson.core.type.TypeReference.class)))
                .thenReturn(deserialized);

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).hasSize(1);
        assertThat(results.get(0).getHotelName()).isEqualTo("Ritz");
        verify(serpApiClient, never()).searchHotels(any());
    }

    @Test
    @DisplayName("CACHE HIT: should return cached airport suggestions without calling SerpAPI")
    void shouldReturnCachedAirports_WhenCacheHit() throws JsonProcessingException {
        String cachedJson = "[{\"iataCode\":\"IST\"}]";
        AirportAutocompleteCache hit = AirportAutocompleteCache.builder()
                .cacheKey("istanbul")
                .resultsJson(cachedJson)
                .cachedAt(Instant.now().minusSeconds(3600))
                .expiresAt(Instant.now().plusSeconds(600000))
                .build();

        when(airportCacheRepo.findByCacheKeyAndExpiresAtAfter(eq("istanbul"), any(Instant.class)))
                .thenReturn(Optional.of(hit));

        SerpApiAirportSuggestion suggestion = new SerpApiAirportSuggestion();
        suggestion.setIataCode("IST");
        when(objectMapper.readValue(eq(cachedJson), any(com.fasterxml.jackson.core.type.TypeReference.class)))
                .thenReturn(List.of(suggestion));

        List<SerpApiAirportSuggestion> results = bookingService.searchAirports("Istanbul");

        assertThat(results).hasSize(1);
        assertThat(results.get(0).getIataCode()).isEqualTo("IST");
        verify(serpApiClient, never()).searchAirports(any());
    }

    // ──────────────────────────────────────────────────────────────
    // Cache MISS — SerpAPI must be called and result saved
    // ──────────────────────────────────────────────────────────────

    @Test
    @DisplayName("CACHE MISS: should call SerpAPI and save result for flights")
    void shouldCallSerpApiAndSave_WhenFlightCacheMiss() throws JsonProcessingException {
        TransportSearchRequestDTO request = flightRequest();

        when(flightCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());

        List<TransportOptionDTO> apiResults = List.of(
                TransportOptionDTO.builder().carrier("TK").price(new BigDecimal("200")).build());
        when(serpApiClient.searchFlights(any())).thenReturn(apiResults);
        when(objectMapper.writeValueAsString(any())).thenReturn("[{\"carrier\":\"TK\"}]");

        // Upsert check — nothing existing
        when(flightCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), eq(Instant.EPOCH)))
                .thenReturn(Optional.empty());

        List<TransportOptionDTO> results = bookingService.searchTransportation(request);

        assertThat(results).hasSize(1);
        verify(serpApiClient, times(1)).searchFlights(any());
        verify(flightCacheRepo, times(1)).save(any(FlightSearchCache.class));
    }

    @Test
    @DisplayName("CACHE MISS: should call SerpAPI and save result for hotels")
    void shouldCallSerpApiAndSave_WhenHotelCacheMiss() throws JsonProcessingException {
        AccommodationSearchRequestDTO request = hotelRequest();

        when(hotelCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> apiResults = List.of(
                AccommodationOptionDTO.builder().hotelName("Ritz").price(new BigDecimal("500")).build());
        when(serpApiClient.searchHotels(any())).thenReturn(apiResults);
        when(objectMapper.writeValueAsString(any())).thenReturn("[{\"hotelName\":\"Ritz\"}]");

        when(hotelCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), eq(Instant.EPOCH)))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).hasSize(1);
        verify(serpApiClient, times(1)).searchHotels(any());
        verify(hotelCacheRepo, times(1)).save(any(HotelSearchCache.class));
    }

    // ──────────────────────────────────────────────────────────────
    // Budget filtering (still applied post-cache-read)
    // ──────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Should filter out flights exceeding budget (cache miss path)")
    void shouldFilterFlights_ExceedingBudget() throws JsonProcessingException {
        TransportSearchRequestDTO request = flightRequest();
        request.setBudget(new BigDecimal("250.00"));

        when(flightCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());

        List<TransportOptionDTO> mockResults = List.of(
                TransportOptionDTO.builder().carrier("TK").price(new BigDecimal("200.00")).build(),
                TransportOptionDTO.builder().carrier("AF").price(new BigDecimal("400.00")).build(),
                TransportOptionDTO.builder().carrier("PC").price(new BigDecimal("150.00")).build());

        when(serpApiClient.searchFlights(any())).thenReturn(mockResults);
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");
        when(flightCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), eq(Instant.EPOCH)))
                .thenReturn(Optional.empty());

        List<TransportOptionDTO> results = bookingService.searchTransportation(request);

        assertThat(results).hasSize(2);
        assertThat(results).extracting(TransportOptionDTO::getCarrier)
                .containsExactlyInAnyOrder("TK", "PC");
    }

    // ──────────────────────────────────────────────────────────────
    // Sorting
    // ──────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Should sort accommodations by PRICE_ASC (cache miss path)")
    void shouldSortAccommodations_PriceAsc() throws JsonProcessingException {
        AccommodationSearchRequestDTO request = hotelRequest();
        request.setSortBy(SortCriteria.PRICE_ASC);

        when(hotelCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> mockResults = List.of(
                AccommodationOptionDTO.builder().hotelName("Expensive").price(new BigDecimal("300.00")).build(),
                AccommodationOptionDTO.builder().hotelName("Cheap").price(new BigDecimal("50.00")).build(),
                AccommodationOptionDTO.builder().hotelName("Mid").price(new BigDecimal("150.00")).build());

        when(serpApiClient.searchHotels(any())).thenReturn(mockResults);
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");
        when(hotelCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), eq(Instant.EPOCH)))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).extracting(AccommodationOptionDTO::getPrice)
                .containsExactly(
                        new BigDecimal("50.00"),
                        new BigDecimal("150.00"),
                        new BigDecimal("300.00"));
    }

    @Test
    @DisplayName("Should sort accommodations by PRICE_DESC (cache miss path)")
    void shouldSortAccommodations_PriceDesc() throws JsonProcessingException {
        AccommodationSearchRequestDTO request = hotelRequest();
        request.setSortBy(SortCriteria.PRICE_DESC);

        when(hotelCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> mockResults = List.of(
                AccommodationOptionDTO.builder().hotelName("Cheap").price(new BigDecimal("50.00")).build(),
                AccommodationOptionDTO.builder().hotelName("Expensive").price(new BigDecimal("300.00")).build());

        when(serpApiClient.searchHotels(any())).thenReturn(mockResults);
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");
        when(hotelCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), eq(Instant.EPOCH)))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).extracting(AccommodationOptionDTO::getPrice)
                .containsExactly(new BigDecimal("300.00"), new BigDecimal("50.00"));
    }

    @Test
    @DisplayName("Should sort accommodations by RATING_DESC (cache miss path)")
    void shouldSortAccommodations_RatingDesc() throws JsonProcessingException {
        AccommodationSearchRequestDTO request = hotelRequest();
        request.setSortBy(SortCriteria.RATING_DESC);

        when(hotelCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> mockResults = List.of(
                AccommodationOptionDTO.builder().hotelName("Low").rating(2.5).build(),
                AccommodationOptionDTO.builder().hotelName("High").rating(4.8).build(),
                AccommodationOptionDTO.builder().hotelName("Mid").rating(3.5).build());

        when(serpApiClient.searchHotels(any())).thenReturn(mockResults);
        when(objectMapper.writeValueAsString(any())).thenReturn("[]");
        when(hotelCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), eq(Instant.EPOCH)))
                .thenReturn(Optional.empty());

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).extracting(AccommodationOptionDTO::getRating)
                .containsExactly(4.8, 3.5, 2.5);
    }

    // ──────────────────────────────────────────────────────────────
    // Empty API responses
    // ──────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Should return empty list when API client returns empty (cache miss path)")
    void shouldReturnEmpty_WhenApiReturnsEmpty() {
        AccommodationSearchRequestDTO request = hotelRequest();

        when(hotelCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());
        when(serpApiClient.searchHotels(any())).thenReturn(Collections.emptyList());

        List<AccommodationOptionDTO> results = bookingService.searchAccommodations(request);

        assertThat(results).isEmpty();
        // Empty results must NOT be cached
        verify(hotelCacheRepo, never()).save(any());
    }

    @Test
    @DisplayName("Should return empty list when flight API returns empty (cache miss path)")
    void shouldReturnEmpty_WhenFlightApiReturnsEmpty() {
        TransportSearchRequestDTO request = flightRequest();

        when(flightCacheRepo.findByCacheKeyAndExpiresAtAfter(anyString(), any(Instant.class)))
                .thenReturn(Optional.empty());
        when(serpApiClient.searchFlights(any())).thenReturn(Collections.emptyList());

        List<TransportOptionDTO> results = bookingService.searchTransportation(request);

        assertThat(results).isEmpty();
        verify(flightCacheRepo, never()).save(any());
    }

    // ──────────────────────────────────────────────────────────────
    // Airport autocomplete validation
    // ──────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Should throw BookingException when airport query is blank")
    void searchAirports_BlankQuery_ThrowsException() {
        assertThatThrownBy(() -> bookingService.searchAirports("   "))
                .isInstanceOf(BookingException.class)
                .hasMessageContaining("must not be blank");
    }

    @Test
    @DisplayName("CACHE MISS: should delegate to SerpApiClient and save airport suggestions")
    void searchAirports_CacheMiss_ReturnsSuggestionsAndSaves() throws JsonProcessingException {
        SerpApiAirportSuggestion ist = new SerpApiAirportSuggestion();
        ist.setIataCode("IST");
        ist.setName("Istanbul Airport");
        ist.setCity("Istanbul");
        ist.setCountry("Turkey");

        when(airportCacheRepo.findByCacheKeyAndExpiresAtAfter(eq("istanbul"), any(Instant.class)))
                .thenReturn(Optional.empty());
        when(serpApiClient.searchAirports(anyString())).thenReturn(List.of(ist));
        when(objectMapper.writeValueAsString(any())).thenReturn("[{\"iataCode\":\"IST\"}]");
        when(airportCacheRepo.findByCacheKeyAndExpiresAtAfter(eq("istanbul"), eq(Instant.EPOCH)))
                .thenReturn(Optional.empty());

        List<SerpApiAirportSuggestion> results = bookingService.searchAirports("istanbul");

        assertThat(results).hasSize(1);
        assertThat(results.get(0).getIataCode()).isEqualTo("IST");
        assertThat(results.get(0).getName()).isEqualTo("Istanbul Airport");
        verify(airportCacheRepo, times(1)).save(any(AirportAutocompleteCache.class));
    }

    // ──────────────────────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────────────────────

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
