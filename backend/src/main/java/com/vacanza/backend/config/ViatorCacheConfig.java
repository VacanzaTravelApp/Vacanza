package com.vacanza.backend.config;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.vacanza.backend.integration.viator.ViatorWaypointPrice;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;

/**
 * In-memory Caffeine cache for Viator waypoint / attraction pricing.
 */
@Configuration
public class ViatorCacheConfig {

    public static final String VIATOR_WAYPOINT_PRICE_CACHE = "viatorWaypointPriceCache";

    @Bean(name = VIATOR_WAYPOINT_PRICE_CACHE)
    @Qualifier(VIATOR_WAYPOINT_PRICE_CACHE)
    public Cache<String, ViatorWaypointPrice> createViatorWaypointPriceCache(ViatorProperties viatorProperties) {
        int ttlMinutes = Math.max(1, viatorProperties.getCacheTtlMinutes());
        return Caffeine.newBuilder()
                .maximumSize(5000)
                .expireAfterWrite(Duration.ofMinutes(ttlMinutes))
                .recordStats()
                .build();
    }
}
