package com.vacanza.backend.repo;

import com.vacanza.backend.entity.cache.FlightSearchCache;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;

@Repository
public interface FlightSearchCacheRepository extends JpaRepository<FlightSearchCache, Long> {

    /** Returns a cache entry only if it exists AND has not yet expired. */
    Optional<FlightSearchCache> findByCacheKeyAndExpiresAtAfter(String cacheKey, Instant now);

    /** Deletes all entries whose expiry is in the past — used by cleanup scheduler. */
    void deleteAllByExpiresAtBefore(Instant cutoff);
}
