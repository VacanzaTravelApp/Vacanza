package com.vacanza.backend.repo;

import com.vacanza.backend.entity.cache.HotelSearchCache;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;

@Repository
public interface HotelSearchCacheRepository extends JpaRepository<HotelSearchCache, Long> {

    Optional<HotelSearchCache> findByCacheKeyAndExpiresAtAfter(String cacheKey, Instant now);

    void deleteAllByExpiresAtBefore(Instant cutoff);
}
