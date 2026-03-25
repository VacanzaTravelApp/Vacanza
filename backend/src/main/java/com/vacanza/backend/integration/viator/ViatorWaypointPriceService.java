package com.vacanza.backend.integration.viator;

import com.github.benmanes.caffeine.cache.Cache;
import com.vacanza.backend.config.ViatorCacheConfig;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.function.Supplier;

/**
 * Loads {@link ViatorWaypointPrice} via {@link ViatorClient} and memoizes by normalized cache key.
 * Second call for the same key does not invoke the Partner API (Caffeine {@code Cache#get}).
 */
@Service
@RequiredArgsConstructor
public class ViatorWaypointPriceService {

    @Qualifier(ViatorCacheConfig.VIATOR_WAYPOINT_PRICE_CACHE)
    private final Cache<String, ViatorWaypointPrice> cache;
    private final ViatorClient viatorClient;

    public ViatorWaypointPrice getMinPriceForAttraction(long attractionId, String currency) {
        String key = ViatorCacheKeys.attraction(attractionId);
        return cache.get(key, k -> loadMinFromProducts(attractionId, currency));
    }

    /**
     * Generic load for keys such as {@link ViatorCacheKeys#destinationWaypoint(long, String)}.
     */
    public ViatorWaypointPrice getOrLoad(String normalizedKey, Supplier<ViatorWaypointPrice> loader) {
        return cache.get(normalizedKey, k -> loader.get());
    }

    private ViatorWaypointPrice loadMinFromProducts(long attractionId, String currency) {
        ViatorProductSearchResponse resp = viatorClient.searchProducts(attractionId, currency);
        Instant now = Instant.now();
        if (resp.getProducts() == null || resp.getProducts().isEmpty()) {
            return ViatorWaypointPrice.empty(now);
        }
        BigDecimal min = null;
        String bestUrl = null;
        String ccy = currency != null ? currency.trim().toUpperCase() : "USD";
        for (var p : resp.getProducts()) {
            if (p.getPricing() == null || p.getPricing().getSummary() == null) {
                continue;
            }
            BigDecimal fp = p.getPricing().getSummary().getFromPrice();
            if (fp == null) {
                continue;
            }
            if (min == null || fp.compareTo(min) < 0) {
                min = fp;
                bestUrl = p.getProductUrl();
                if (p.getPricing().getCurrency() != null) {
                    ccy = p.getPricing().getCurrency();
                }
            }
        }
        if (min == null) {
            return ViatorWaypointPrice.empty(now);
        }
        return new ViatorWaypointPrice(min, ccy, bestUrl, now);
    }
}
