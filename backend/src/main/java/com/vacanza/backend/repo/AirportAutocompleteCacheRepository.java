package com.vacanza.backend.repo;

import com.vacanza.backend.entity.cache.AirportAutocompleteCache;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;

@Repository
public interface AirportAutocompleteCacheRepository extends JpaRepository<AirportAutocompleteCache, Long> {

    Optional<AirportAutocompleteCache> findByCacheKeyAndExpiresAtAfter(String cacheKey, Instant now);

    void deleteAllByExpiresAtBefore(Instant cutoff);
}
