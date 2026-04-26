package com.vacanza.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.vacanza.backend.dto.response.UserPreferencesResponseDTO;
import com.vacanza.backend.dto.response.WaypointPricing;
import com.vacanza.backend.dto.response.WaypointPricingStatus;
import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.integration.viator.ViatorPartnerUnavailableException;
import com.vacanza.backend.integration.viator.ViatorWaypointPrice;
import com.vacanza.backend.integration.viator.ViatorWaypointPriceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * Resolves Viator product pricing per route waypoint using {@link AiRouteService} (ownership)
 * and the Partner API.
 *
 * <p>A short-term route-level cache (10 min TTL) ensures that repeated "Show prices" clicks
 * for the same route always return the same set of results within a session.
 * Unlike the old per-attraction cache, this cache holds the full resolved list per routeId,
 * so Viator is only called once per route per 10-minute window.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ViatorPricingService {

    /** Route-level result cache: routeId → resolved pricing list, 10-minute TTL. */
    private final Cache<UUID, List<WaypointPricing>> routeResultCache = Caffeine.newBuilder()
            .maximumSize(1000)
            .expireAfterWrite(Duration.ofMinutes(10))
            .build();

    private final AiRouteService aiRouteService;
    private final ObjectMapper objectMapper;
    private final ViatorWaypointPriceService viatorWaypointPriceService;
    private final UserPreferencesService userPreferencesService;
    private final ExchangeRateService exchangeRateService;

    /**
     * @return empty if the route does not exist for this user (ownership); otherwise a list of
     *         waypoint rows. Use {@link WaypointPricing#status()} — {@link WaypointPricingStatus#PARTNER_UNAVAILABLE}
     *         when Viator cannot be reached (network/timeout).
     */
    public Optional<List<WaypointPricing>> loadPricing(UUID routeId, User user) {
        // Ownership check always runs (no ownership bypass via cache).
        Optional<AiRoute> routeOpt = aiRouteService.getRoute(routeId, user);
        if (routeOpt.isEmpty()) {
            return Optional.empty();
        }
        // Return cached result if available — ensures consistent count across repeated clicks.
        List<WaypointPricing> cached = routeResultCache.getIfPresent(routeId);
        if (cached != null) {
            log.debug("[VIATOR-PRICING] cache hit for route {}", routeId);
            return Optional.of(cached);
        }
        String targetCurrency = userPreferencesService.getPreferencesByUser(user)
                .map(UserPreferencesResponseDTO::getBudgetCurrency)
                .filter(StringUtils::hasText)
                .orElse(null);
        AiRoute route = routeOpt.get();
        AiChatDto.RouteData routeData;
        try {
            routeData = objectMapper.readValue(route.getRouteJson(), AiChatDto.RouteData.class);
        } catch (Exception e) {
            log.warn("[VIATOR-PRICING] cannot parse routeJson for {}: {}", routeId, e.getMessage());
            return Optional.of(List.of());
        }
        List<WaypointRef> waypoints = flattenWaypoints(routeData);
        if (waypoints.isEmpty()) {
            return Optional.of(List.of());
        }
        List<CompletableFuture<WaypointPricing>> futures = new ArrayList<>();
        for (WaypointRef ref : waypoints) {
            CompletableFuture<WaypointPricing> f = CompletableFuture
                    .supplyAsync(() -> priceWaypoint(ref, targetCurrency), ForkJoinPool.commonPool())
                    .orTimeout(17, TimeUnit.SECONDS)
                    .exceptionally(ex -> fallback(ref, ex));
            futures.add(f);
        }
        CompletableFuture.allOf(futures.toArray(CompletableFuture[]::new)).join();
        List<WaypointPricing> result = futures.stream().map(CompletableFuture::join).toList();
        routeResultCache.put(routeId, result);
        return Optional.of(result);
    }

    private WaypointPricing priceWaypoint(WaypointRef ref, String targetCurrency) {
        AiChatDto.RouteWaypoint wp = ref.wp();
        String name = wp.getName();
        if (!StringUtils.hasText(name)) {
            return WaypointPricing.noName(ref.day(), wp.getOrder());
        }
        String trimmed = name.trim();
        ViatorWaypointPrice vp = viatorWaypointPriceService.getPrice(trimmed, wp.getCategory(), "USD");
        boolean found = vp.hasPrice();
        BigDecimal displayPrice = vp.minPrice();
        String displayCurrency = vp.currency();
        if (found && displayPrice != null && StringUtils.hasText(targetCurrency)
                && StringUtils.hasText(displayCurrency)
                && !targetCurrency.equalsIgnoreCase(displayCurrency)) {
            try {
                displayPrice = exchangeRateService.convert(displayPrice, displayCurrency, targetCurrency);
                displayCurrency = targetCurrency.toUpperCase();
            } catch (Exception e) {
                log.warn("[VIATOR-PRICING] currency conversion {}->{} failed for '{}': {}",
                        displayCurrency, targetCurrency, trimmed, e.getMessage());
            }
        }
        WaypointPricingStatus status = found ? WaypointPricingStatus.FOUND : WaypointPricingStatus.NO_MATCH;
        return new WaypointPricing(
                trimmed,
                ref.day(),
                wp.getOrder(),
                displayPrice,
                displayCurrency,
                vp.productUrl(),
                vp.productTitle(),
                found,
                status,
                null);
    }

    private WaypointPricing fallback(WaypointRef ref, Throwable ex) {
        String nm = ref.wp().getName() != null ? ref.wp().getName() : "";
        int depth = 0;
        for (Throwable t = ex; t != null && depth < 20; t = t.getCause(), depth++) {
            if (t instanceof ViatorPartnerUnavailableException) {
                log.warn("[VIATOR-PRICING] partner unavailable day={} order={}", ref.day(), ref.wp().getOrder());
                return new WaypointPricing(
                        nm, ref.day(), ref.wp().getOrder(),
                        null, null, null, null,
                        false, WaypointPricingStatus.PARTNER_UNAVAILABLE,
                        "Viator API'ye şu an ulaşılamıyor (ağ veya sunucu)");
            }
            if (t instanceof TimeoutException) {
                log.warn("[VIATOR-PRICING] timeout day={} order={}", ref.day(), ref.wp().getOrder());
                return new WaypointPricing(
                        nm, ref.day(), ref.wp().getOrder(),
                        null, null, null, null,
                        false, WaypointPricingStatus.PARTNER_UNAVAILABLE,
                        "Viator isteği zaman aşımına uğradı");
            }
        }
        log.warn("[VIATOR-PRICING] waypoint failed day={} order={}: {}",
                ref.day(), ref.wp().getOrder(), ex != null ? ex.getMessage() : "");
        return new WaypointPricing(
                nm, ref.day(), ref.wp().getOrder(),
                null, null, null, null,
                false, WaypointPricingStatus.NO_MATCH, null);
    }

    private static List<WaypointRef> flattenWaypoints(AiChatDto.RouteData routeData) {
        if (routeData == null || routeData.getDays() == null) {
            return List.of();
        }
        List<WaypointRef> out = new ArrayList<>();
        for (AiChatDto.DayPlan dayPlan : routeData.getDays()) {
            if (dayPlan == null || dayPlan.getWaypoints() == null) {
                continue;
            }
            int dayNum = dayPlan.getDay();
            for (AiChatDto.RouteWaypoint wp : dayPlan.getWaypoints()) {
                if (wp == null) {
                    continue;
                }
                int d = wp.getDay() > 0 ? wp.getDay() : dayNum;
                out.add(new WaypointRef(wp, d));
            }
        }
        out.sort(Comparator.comparing(WaypointRef::day).thenComparingInt(r -> r.wp().getOrder()));
        return out;
    }

    private record WaypointRef(AiChatDto.RouteWaypoint wp, int day) {}
}
