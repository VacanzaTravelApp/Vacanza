package com.vacanza.backend.repo;

import com.vacanza.backend.entity.cache.ApiCache;
import com.vacanza.backend.entity.cache.ApiCacheType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;

@Repository
public interface ApiCacheRepository extends JpaRepository<ApiCache, Long> {

    /**
     * Returns a cache entry only if it exists AND has not yet expired.
     * This is the only read path — expired entries are never returned.
     */
    Optional<ApiCache> findByCacheTypeAndCacheKeyAndExpiresAtAfter(
            ApiCacheType cacheType, String cacheKey, Instant now);

    /**
     * Find by type+key regardless of expiry — used for upsert (overwrite expired entry).
     */
    Optional<ApiCache> findByCacheTypeAndCacheKey(
            ApiCacheType cacheType, String cacheKey);

    /**
     * Nightly cleanup — delete all rows whose TTL has passed.
     */
    void deleteAllByExpiresAtBefore(Instant cutoff);
}
