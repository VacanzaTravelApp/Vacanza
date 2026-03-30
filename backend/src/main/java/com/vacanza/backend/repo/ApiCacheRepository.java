package com.vacanza.backend.repo;

import com.vacanza.backend.entity.cache.ApiCache;
import com.vacanza.backend.entity.cache.ApiCacheType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;

@Repository
public interface ApiCacheRepository extends JpaRepository<ApiCache, Long> {

    Optional<ApiCache> findByCacheTypeAndCacheKeyAndExpiresAtAfter(
            ApiCacheType cacheType, String cacheKey, Instant now);

    Optional<ApiCache> findByCacheTypeAndCacheKey(
            ApiCacheType cacheType, String cacheKey);

    void deleteAllByExpiresAtBefore(Instant cutoff);
}
