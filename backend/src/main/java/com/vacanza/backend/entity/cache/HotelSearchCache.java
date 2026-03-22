package com.vacanza.backend.entity.cache;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * DB cache entry for Google Hotels search results via SerpAPI.
 * TTL: 12 hours.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(
        name = "hotel_search_cache",
        indexes = @Index(name = "idx_hotel_cache_key", columnList = "cache_key")
)
public class HotelSearchCache {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "cache_key", nullable = false, unique = true, length = 512)
    private String cacheKey;

    /** JSON-serialized List<AccommodationOptionDTO> */
    @Column(name = "results_json", nullable = false, columnDefinition = "TEXT")
    private String resultsJson;

    @Column(name = "cached_at", nullable = false)
    private Instant cachedAt;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;
}
