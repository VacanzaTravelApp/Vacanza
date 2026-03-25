package com.vacanza.backend.config;

import com.github.benmanes.caffeine.cache.Cache;
import com.vacanza.backend.integration.viator.ViatorWaypointPrice;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Periodically logs Caffeine stats for the Viator waypoint price cache (hits/misses).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ViatorCacheMetricsLogger {

    @Qualifier(ViatorCacheConfig.VIATOR_WAYPOINT_PRICE_CACHE)
    private final Cache<String, ViatorWaypointPrice> waypointPriceCache;

    @Scheduled(fixedDelayString = "${viator.cache-metrics-log-interval-ms:60000}")
    public void logViatorCacheStats() {
        var s = waypointPriceCache.stats();
        log.info(
                "[VIATOR-CACHE] hits={} misses={} hitRate={} requestCount={} evictionCount={} estimatedSize={}",
                s.hitCount(),
                s.missCount(),
                String.format(java.util.Locale.US, "%.4f", s.hitRate()),
                s.requestCount(),
                s.evictionCount(),
                waypointPriceCache.estimatedSize());
    }
}
