package com.vacanza.backend.entity.cache;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * Generic, single-table cache for all SerpAPI call results.
 * <p>
 * Each row stores one JSON-serialized API response, keyed by
 * {@code (cacheType, cacheKey)} with a TTL via {@code expiresAt}.
 * <p>
 * TTLs by type:
 * <ul>
 *   <li>AIRPORT — 30 days  (IATA codes never change)</li>
 *   <li>HOTEL   — 12 hours (prices are fairly stable)</li>
 *   <li>FLIGHT  — 6 hours  (prices change intra-day)</li>
 * </ul>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(
        name = "api_cache",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_api_cache_type_key",
                columnNames = {"cache_type", "cache_key"}
        ),
        indexes = @Index(
                name = "idx_api_cache_expires",
                columnList = "expires_at"
        )
)
public class ApiCache {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "cache_type", nullable = false, length = 20)
    private ApiCacheType cacheType;

    @Column(name = "cache_key", nullable = false, length = 512)
    private String cacheKey;

    /** JSON-serialized API response (List of DTOs). */
    @Column(name = "results_json", nullable = false, columnDefinition = "TEXT")
    private String resultsJson;

    @Column(name = "cached_at", nullable = false)
    private Instant cachedAt;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;
}
