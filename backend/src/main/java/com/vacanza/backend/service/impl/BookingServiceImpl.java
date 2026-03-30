package com.vacanza.backend.service.impl;

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
import com.vacanza.backend.service.BookingService;
import com.vacanza.backend.util.CacheKeys;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class BookingServiceImpl implements BookingService {

        // TTL constants
        private static final long FLIGHT_TTL_HOURS  = 6;
        private static final long HOTEL_TTL_HOURS   = 12;
        private static final long AIRPORT_TTL_DAYS  = 30;

        private final SerpApiClient serpApiClient;
        private final ApiCacheRepository cacheRepo;
        private final ObjectMapper objectMapper;

        // ──────────────────────────────────────────────
        // Accommodations (DB cache — 12h TTL)
        // ──────────────────────────────────────────────

        @Override
        public List<AccommodationOptionDTO> searchAccommodations(AccommodationSearchRequestDTO request) {
                String key = CacheKeys.hotel(request);

                Optional<ApiCache> cached = cacheRepo
                        .findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                                ApiCacheType.HOTEL, key, Instant.now());

                if (cached.isPresent()) {
                        log.info("[CACHE HIT] Hotel: key={}", key);
                        List<AccommodationOptionDTO> results = deserialize(
                                cached.get().getResultsJson(),
                                new TypeReference<>() {});
                        return sortAccommodations(results, request.getSortBy());
                }

                log.info("[CACHE MISS] Hotel: key={} — calling SerpAPI", key);
                List<AccommodationOptionDTO> results = serpApiClient.searchHotels(request);

                if (!results.isEmpty()) {
                        upsertCache(ApiCacheType.HOTEL, key, serialize(results),
                                HOTEL_TTL_HOURS, ChronoUnit.HOURS);
                }

                return sortAccommodations(results, request.getSortBy());
        }

        // ──────────────────────────────────────────────
        // Flights (DB cache — 6h TTL)
        // ──────────────────────────────────────────────

        @Override
        public List<TransportOptionDTO> searchTransportation(TransportSearchRequestDTO request) {
                String key = CacheKeys.flight(request);

                Optional<ApiCache> cached = cacheRepo
                        .findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                                ApiCacheType.FLIGHT, key, Instant.now());

                if (cached.isPresent()) {
                        log.info("[CACHE HIT] Flight: key={}", key);
                        List<TransportOptionDTO> results = deserialize(
                                cached.get().getResultsJson(),
                                new TypeReference<>() {});
                        return applyBudgetAndSort(results, request);
                }

                log.info("[CACHE MISS] Flight: key={} — calling SerpAPI", key);
                List<TransportOptionDTO> results = serpApiClient.searchFlights(request);

                if (!results.isEmpty()) {
                        upsertCache(ApiCacheType.FLIGHT, key, serialize(results),
                                FLIGHT_TTL_HOURS, ChronoUnit.HOURS);
                }

                return applyBudgetAndSort(results, request);
        }

        // ──────────────────────────────────────────────
        // Airport autocomplete (DB cache — 30 day TTL)
        // ──────────────────────────────────────────────

        @Override
        public List<SerpApiAirportSuggestion> searchAirports(String query) {
                if (query == null || query.isBlank()) {
                        throw new BookingException(
                                "Airport search query must not be blank",
                                HttpStatus.BAD_REQUEST);
                }

                String key = CacheKeys.airport(query);

                Optional<ApiCache> cached = cacheRepo
                        .findByCacheTypeAndCacheKeyAndExpiresAtAfter(
                                ApiCacheType.AIRPORT, key, Instant.now());

                if (cached.isPresent()) {
                        log.info("[CACHE HIT] Airport: key={}", key);
                        return deserialize(cached.get().getResultsJson(),
                                new TypeReference<>() {});
                }

                log.info("[CACHE MISS] Airport: key={} — calling SerpAPI", key);
                List<SerpApiAirportSuggestion> results = serpApiClient.searchAirports(query);

                if (!results.isEmpty()) {
                        upsertCache(ApiCacheType.AIRPORT, key, serialize(results),
                                AIRPORT_TTL_DAYS, ChronoUnit.DAYS);
                }

                return results;
        }

        // ──────────────────────────────────────────────
        // Hotel destination autocomplete
        // Reuses airport autocomplete data — ZERO extra SerpAPI calls
        // ──────────────────────────────────────────────

        @Override
        public List<DestinationSuggestionDTO> searchDestinations(String query) {
                if (query == null || query.isBlank()) {
                        throw new BookingException(
                                "Destination search query must not be blank",
                                HttpStatus.BAD_REQUEST);
                }

                // Reuse the same airport autocomplete (already cached with 30d TTL)
                List<SerpApiAirportSuggestion> airports = searchAirports(query);

                // Extract unique city+country pairs, build destination suggestions
                Set<String> seen = new LinkedHashSet<>();
                List<DestinationSuggestionDTO> destinations = new ArrayList<>();

                for (SerpApiAirportSuggestion s : airports) {
                        String city = s.getCity();
                        String country = s.getCountry();
                        if (city == null || city.isBlank()) continue;

                        String uniqueKey = (city + "_" + (country != null ? country : "")).toLowerCase();
                        if (!seen.add(uniqueKey)) continue;  // duplicate city+country

                        String displayName = country != null && !country.isBlank()
                                ? city + ", " + country
                                : city;

                        destinations.add(DestinationSuggestionDTO.builder()
                                .city(city)
                                .country(country)
                                .displayName(displayName)
                                .searchQuery("Hotels in " + city)
                                .build());
                }

                log.info("[DESTINATION] '{}' → {} unique destinations", query, destinations.size());
                return destinations;
        }

        // ──────────────────────────────────────────────
        // Cache helpers
        // ──────────────────────────────────────────────

        private void upsertCache(ApiCacheType type, String key, String json,
                                 long ttlAmount, ChronoUnit ttlUnit) {
                Instant now = Instant.now();
                Instant expiresAt = now.plus(ttlAmount, ttlUnit);

                Optional<ApiCache> existing = cacheRepo.findByCacheTypeAndCacheKey(type, key);
                if (existing.isPresent()) {
                        ApiCache row = existing.get();
                        row.setResultsJson(json);
                        row.setCachedAt(now);
                        row.setExpiresAt(expiresAt);
                        cacheRepo.save(row);
                } else {
                        cacheRepo.save(ApiCache.builder()
                                .cacheType(type)
                                .cacheKey(key)
                                .resultsJson(json)
                                .cachedAt(now)
                                .expiresAt(expiresAt)
                                .build());
                }
        }

        private String serialize(Object obj) {
                try {
                        return objectMapper.writeValueAsString(obj);
                } catch (JsonProcessingException e) {
                        log.error("[CACHE] Serialization failed: {}", e.getMessage());
                        throw new BookingException("Cache serialization error",
                                HttpStatus.INTERNAL_SERVER_ERROR);
                }
        }

        private <T> T deserialize(String json, TypeReference<T> type) {
                try {
                        return objectMapper.readValue(json, type);
                } catch (JsonProcessingException e) {
                        log.error("[CACHE] Deserialization failed: {}", e.getMessage());
                        throw new BookingException("Cache deserialization error",
                                HttpStatus.INTERNAL_SERVER_ERROR);
                }
        }

        // ──────────────────────────────────────────────
        // Budget & sort
        // ──────────────────────────────────────────────

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

                Comparator<AccommodationOptionDTO> comparator = switch (sortBy) {
                        case PRICE_ASC -> Comparator.comparing(
                                        AccommodationOptionDTO::getPrice,
                                        Comparator.nullsLast(Comparator.naturalOrder()));
                        case PRICE_DESC -> Comparator.comparing(
                                        AccommodationOptionDTO::getPrice,
                                        Comparator.nullsLast(Comparator.reverseOrder()));
                        case RATING_DESC -> Comparator.comparing(
                                        AccommodationOptionDTO::getRating,
                                        Comparator.nullsLast(Comparator.reverseOrder()));
                };

                return results.stream().sorted(comparator).collect(Collectors.toList());
        }

        private List<TransportOptionDTO> sortTransportation(
                        List<TransportOptionDTO> results, SortCriteria sortBy) {

                if (sortBy == null) return results;

                Comparator<TransportOptionDTO> comparator = switch (sortBy) {
                        case PRICE_ASC -> Comparator.comparing(
                                        TransportOptionDTO::getPrice,
                                        Comparator.nullsLast(Comparator.naturalOrder()));
                        case PRICE_DESC -> Comparator.comparing(
                                        TransportOptionDTO::getPrice,
                                        Comparator.nullsLast(Comparator.reverseOrder()));
                        case RATING_DESC -> Comparator.comparing(
                                        TransportOptionDTO::getPrice,
                                        Comparator.nullsLast(Comparator.naturalOrder()));
                        // Flights don't have rating, fallback to price asc
                };

                return results.stream().sorted(comparator).collect(Collectors.toList());
        }
}
