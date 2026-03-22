package com.vacanza.backend.entity.cache;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * DB cache entry for Google Flights autocomplete results via SerpAPI.
 * TTL: 7 days (IATA codes and city names rarely change).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(
        name = "airport_autocomplete_cache",
        indexes = @Index(name = "idx_airport_cache_key", columnList = "cache_key")
)
public class AirportAutocompleteCache {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "cache_key", nullable = false, unique = true, length = 256)
    private String cacheKey;

    /** JSON-serialized List<SerpApiAirportSuggestion> */
    @Column(name = "results_json", nullable = false, columnDefinition = "TEXT")
    private String resultsJson;

    @Column(name = "cached_at", nullable = false)
    private Instant cachedAt;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;
}
