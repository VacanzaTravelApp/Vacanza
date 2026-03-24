package com.vacanza.backend.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
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
import com.vacanza.backend.service.BookingService;
import com.vacanza.backend.util.CacheKeyBuilder;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class BookingServiceImpl implements BookingService {

    // TTL constants
    private static final long FLIGHT_CACHE_TTL_HOURS  = 6;
    private static final long HOTEL_CACHE_TTL_HOURS   = 12;
    private static final long AIRPORT_CACHE_TTL_DAYS  = 7;

    private final SerpApiClient serpApiClient;
    private final ObjectMapper objectMapper;

    private final FlightSearchCacheRepository    flightCacheRepo;
    private final HotelSearchCacheRepository     hotelCacheRepo;
    private final AirportAutocompleteCacheRepository airportCacheRepo;

    // ──────────────────────────────────────────────────────────────
    // Accommodations
    // ──────────────────────────────────────────────────────────────

    @Override
    public List<AccommodationOptionDTO> searchAccommodations(AccommodationSearchRequestDTO request) {
        String key = CacheKeyBuilder.forHotel(request);

        Optional<HotelSearchCache> cached = hotelCacheRepo
                .findByCacheKeyAndExpiresAtAfter(key, Instant.now());

        if (cached.isPresent()) {
            log.info("[CACHE HIT] Hotel search: key={}", key);
            List<AccommodationOptionDTO> results = deserialize(
                    cached.get().getResultsJson(),
                    new TypeReference<>() {});
            return sortAccommodations(results, request.getSortBy());
        }

        log.info("[CACHE MISS] Hotel search: key={} — calling SerpAPI", key);
        List<AccommodationOptionDTO> results = serpApiClient.searchHotels(request);

        if (!results.isEmpty()) {
            Instant now = Instant.now();
            HotelSearchCache entry = HotelSearchCache.builder()
                    .cacheKey(key)
                    .resultsJson(serialize(results))
                    .cachedAt(now)
                    .expiresAt(now.plus(HOTEL_CACHE_TTL_HOURS, ChronoUnit.HOURS))
                    .build();

            // Upsert: if key already exists (race condition), overwrite
            hotelCacheRepo.findByCacheKeyAndExpiresAtAfter(key, Instant.EPOCH)
                    .ifPresentOrElse(existing -> {
                        existing.setResultsJson(entry.getResultsJson());
                        existing.setCachedAt(entry.getCachedAt());
                        existing.setExpiresAt(entry.getExpiresAt());
                        hotelCacheRepo.save(existing);
                    }, () -> hotelCacheRepo.save(entry));
        }

        return sortAccommodations(results, request.getSortBy());
    }

    // ──────────────────────────────────────────────────────────────
    // Flights
    // ──────────────────────────────────────────────────────────────

    @Override
    public List<TransportOptionDTO> searchTransportation(TransportSearchRequestDTO request) {
        String key = CacheKeyBuilder.forFlight(request);

        Optional<FlightSearchCache> cached = flightCacheRepo
                .findByCacheKeyAndExpiresAtAfter(key, Instant.now());

        if (cached.isPresent()) {
            log.info("[CACHE HIT] Flight search: key={}", key);
            List<TransportOptionDTO> results = deserialize(
                    cached.get().getResultsJson(),
                    new TypeReference<>() {});
            return applyBudgetAndSort(results, request);
        }

        log.info("[CACHE MISS] Flight search: key={} — calling SerpAPI", key);
        List<TransportOptionDTO> results = serpApiClient.searchFlights(request);

        if (!results.isEmpty()) {
            Instant now = Instant.now();
            FlightSearchCache entry = FlightSearchCache.builder()
                    .cacheKey(key)
                    .resultsJson(serialize(results))
                    .cachedAt(now)
                    .expiresAt(now.plus(FLIGHT_CACHE_TTL_HOURS, ChronoUnit.HOURS))
                    .build();

            flightCacheRepo.findByCacheKeyAndExpiresAtAfter(key, Instant.EPOCH)
                    .ifPresentOrElse(existing -> {
                        existing.setResultsJson(entry.getResultsJson());
                        existing.setCachedAt(entry.getCachedAt());
                        existing.setExpiresAt(entry.getExpiresAt());
                        flightCacheRepo.save(existing);
                    }, () -> flightCacheRepo.save(entry));
        }

        return applyBudgetAndSort(results, request);
    }

    // ──────────────────────────────────────────────────────────────
    // Airport autocomplete
    // ──────────────────────────────────────────────────────────────

    @Override
    public List<SerpApiAirportSuggestion> searchAirports(String query) {
        if (query == null || query.isBlank()) {
            throw new BookingException(
                    "Airport search query must not be blank",
                    HttpStatus.BAD_REQUEST);
        }

        String key = CacheKeyBuilder.forAirport(query);

        Optional<AirportAutocompleteCache> cached = airportCacheRepo
                .findByCacheKeyAndExpiresAtAfter(key, Instant.now());

        if (cached.isPresent()) {
            String json = cached.get().getResultsJson();
            // Treat a cached empty result as a miss — could be a stale entry
            // from before the suggested_locations JSON mapping fix.
            if (json != null && !json.isBlank() && !json.equals("[]")) {
                log.info("[CACHE HIT] Airport autocomplete: key={}", key);
                return deserialize(json, new TypeReference<>() {});
            }
            log.info("[CACHE BYPASS] Airport autocomplete: key={} had empty cached result, re-fetching", key);
        }

        log.info("[CACHE MISS] Airport autocomplete: key={} — calling SerpAPI", key);
        List<SerpApiAirportSuggestion> results = serpApiClient.searchAirports(query);

        if (!results.isEmpty()) {
            Instant now = Instant.now();
            AirportAutocompleteCache entry = AirportAutocompleteCache.builder()
                    .cacheKey(key)
                    .resultsJson(serialize(results))
                    .cachedAt(now)
                    .expiresAt(now.plus(AIRPORT_CACHE_TTL_DAYS, ChronoUnit.DAYS))
                    .build();

            airportCacheRepo.findByCacheKeyAndExpiresAtAfter(key, Instant.EPOCH)
                    .ifPresentOrElse(existing -> {
                        existing.setResultsJson(entry.getResultsJson());
                        existing.setCachedAt(entry.getCachedAt());
                        existing.setExpiresAt(entry.getExpiresAt());
                        airportCacheRepo.save(existing);
                    }, () -> airportCacheRepo.save(entry));
        }

        return results;
    }


    // ──────────────────────────────────────────────────────────────
    // Private helpers
    // ──────────────────────────────────────────────────────────────

    private List<TransportOptionDTO> applyBudgetAndSort(
            List<TransportOptionDTO> results, TransportSearchRequestDTO request) {

        if (request.getBudget() != null) {
            results = results.stream()
                    .filter(opt -> opt.getPrice() != null
                            && opt.getPrice().compareTo(request.getBudget()) <= 0)
                    .collect(Collectors.toList());
        }
        return sortTransportation(results, request.getSortBy());
    }

    private List<AccommodationOptionDTO> sortAccommodations(
            List<AccommodationOptionDTO> results, SortCriteria sortBy) {

        if (sortBy == null) return results;

        Comparator<AccommodationOptionDTO> cmp = switch (sortBy) {
            case PRICE_ASC  -> Comparator.comparing(AccommodationOptionDTO::getPrice,
                    Comparator.nullsLast(Comparator.naturalOrder()));
            case PRICE_DESC -> Comparator.comparing(AccommodationOptionDTO::getPrice,
                    Comparator.nullsLast(Comparator.reverseOrder()));
            case RATING_DESC -> Comparator.comparing(AccommodationOptionDTO::getRating,
                    Comparator.nullsLast(Comparator.reverseOrder()));
        };

        return results.stream().sorted(cmp).collect(Collectors.toList());
    }

    private List<TransportOptionDTO> sortTransportation(
            List<TransportOptionDTO> results, SortCriteria sortBy) {

        if (sortBy == null) return results;

        Comparator<TransportOptionDTO> cmp = switch (sortBy) {
            case PRICE_ASC  -> Comparator.comparing(TransportOptionDTO::getPrice,
                    Comparator.nullsLast(Comparator.naturalOrder()));
            case PRICE_DESC -> Comparator.comparing(TransportOptionDTO::getPrice,
                    Comparator.nullsLast(Comparator.reverseOrder()));
            case RATING_DESC -> Comparator.comparing(TransportOptionDTO::getPrice,
                    Comparator.nullsLast(Comparator.naturalOrder())); // flights have no rating
        };

        return results.stream().sorted(cmp).collect(Collectors.toList());
    }

    private String serialize(Object obj) {
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (JsonProcessingException e) {
            log.error("[CACHE] Serialization failed: {}", e.getMessage());
            throw new BookingException("Cache serialization error", HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    private <T> T deserialize(String json, TypeReference<T> type) {
        try {
            return objectMapper.readValue(json, type);
        } catch (JsonProcessingException e) {
            log.error("[CACHE] Deserialization failed: {}", e.getMessage());
            throw new BookingException("Cache deserialization error", HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
