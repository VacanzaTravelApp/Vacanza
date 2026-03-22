package com.vacanza.backend.component;

import com.vacanza.backend.repo.AirportAutocompleteCacheRepository;
import com.vacanza.backend.repo.FlightSearchCacheRepository;
import com.vacanza.backend.repo.HotelSearchCacheRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

/**
 * Nightly job that deletes expired SerpAPI cache entries from the database.
 * Runs at 03:00 every day to keep tables lean.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class CacheCleanupScheduler {

    private final FlightSearchCacheRepository    flightCacheRepo;
    private final HotelSearchCacheRepository     hotelCacheRepo;
    private final AirportAutocompleteCacheRepository airportCacheRepo;

    @Transactional
    @Scheduled(cron = "0 0 3 * * *")
    public void cleanupExpiredCacheEntries() {
        Instant now = Instant.now();
        log.info("[CACHE CLEANUP] Starting expired cache entry cleanup at {}", now);

        flightCacheRepo.deleteAllByExpiresAtBefore(now);
        hotelCacheRepo.deleteAllByExpiresAtBefore(now);
        airportCacheRepo.deleteAllByExpiresAtBefore(now);

        log.info("[CACHE CLEANUP] Cleanup complete");
    }
}
