package com.vacanza.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.dto.response.WaypointPricing;
import com.vacanza.backend.dto.response.WaypointPricingStatus;
import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.integration.viator.ViatorAttractionSearchResponse;
import com.vacanza.backend.integration.viator.ViatorCacheKeys;
import com.vacanza.backend.integration.viator.ViatorClient;
import com.vacanza.backend.integration.viator.ViatorPartnerUnavailableException;
import com.vacanza.backend.integration.viator.ViatorWaypointPrice;
import com.vacanza.backend.integration.viator.ViatorWaypointPriceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.Instant;
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
 * and the in-memory cache + Partner API.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ViatorPricingService {

    private static final String DEFAULT_LANG = "en";

    private final AiRouteService aiRouteService;
    private final ObjectMapper objectMapper;
    private final ViatorClient viatorClient;
    private final ViatorWaypointPriceService viatorWaypointPriceService;

    /**
     * @return empty if the route does not exist for this user (ownership); otherwise a list of
     *         waypoint rows. Use {@link WaypointPricing#status()} — {@link WaypointPricingStatus#PARTNER_UNAVAILABLE}
     *         when Viator cannot be reached (network/timeout).
     */
    public Optional<List<WaypointPricing>> loadPricing(UUID routeId, User user) {
        Optional<AiRoute> routeOpt = aiRouteService.getRoute(routeId, user);
        if (routeOpt.isEmpty()) {
            return Optional.empty();
        }
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
                    .supplyAsync(() -> priceWaypoint(route.getRouteId(), ref), ForkJoinPool.commonPool())
                    .orTimeout(9, TimeUnit.SECONDS)
                    .exceptionally(ex -> fallback(ref, ex));
            futures.add(f);
        }
        CompletableFuture.allOf(futures.toArray(CompletableFuture[]::new)).join();
        return Optional.of(futures.stream().map(CompletableFuture::join).toList());
    }

    private WaypointPricing priceWaypoint(UUID routeId, WaypointRef ref) {
        AiChatDto.RouteWaypoint wp = ref.wp();
        String name = wp.getName();
        if (!StringUtils.hasText(name)) {
            return WaypointPricing.noName(ref.day(), wp.getOrder());
        }
        String trimmed = name.trim();
        String key = ViatorCacheKeys.routeWaypoint(routeId, ref.day(), wp.getOrder(), trimmed);
        ViatorWaypointPrice vp = viatorWaypointPriceService.getOrLoad(key, () -> {
            ViatorAttractionSearchResponse search = viatorClient.searchAttractions(trimmed, DEFAULT_LANG);
            Long id = firstAttractionId(search);
            if (id == null) {
                return ViatorWaypointPrice.empty(Instant.now());
            }
            return viatorWaypointPriceService.getMinPriceForAttraction(id, "USD");
        });
        boolean found = vp.hasPrice();
        BigDecimal minUsd = vp.minPrice();
        WaypointPricingStatus status = found ? WaypointPricingStatus.FOUND : WaypointPricingStatus.NO_MATCH;
        return new WaypointPricing(
                trimmed,
                ref.day(),
                wp.getOrder(),
                minUsd,
                vp.currency(),
                vp.productUrl(),
                found,
                status,
                null);
    }

    private static Long firstAttractionId(ViatorAttractionSearchResponse resp) {
        if (resp == null || resp.getData() == null || resp.getData().isEmpty()) {
            return null;
        }
        return resp.getData().get(0).getId();
    }

    private WaypointPricing fallback(WaypointRef ref, Throwable ex) {
        String nm = ref.wp().getName() != null ? ref.wp().getName() : "";
        int depth = 0;
        for (Throwable t = ex; t != null && depth < 20; t = t.getCause(), depth++) {
            if (t instanceof ViatorPartnerUnavailableException) {
                log.warn("[VIATOR-PRICING] partner unavailable day={} order={}", ref.day(), ref.wp().getOrder());
                return new WaypointPricing(
                        nm,
                        ref.day(),
                        ref.wp().getOrder(),
                        null,
                        null,
                        null,
                        false,
                        WaypointPricingStatus.PARTNER_UNAVAILABLE,
                        "Viator API'ye şu an ulaşılamıyor (ağ veya sunucu)");
            }
            if (t instanceof TimeoutException) {
                log.warn("[VIATOR-PRICING] timeout day={} order={}", ref.day(), ref.wp().getOrder());
                return new WaypointPricing(
                        nm,
                        ref.day(),
                        ref.wp().getOrder(),
                        null,
                        null,
                        null,
                        false,
                        WaypointPricingStatus.PARTNER_UNAVAILABLE,
                        "Viator isteği zaman aşımına uğradı");
            }
        }
        log.warn("[VIATOR-PRICING] waypoint failed day={} order={}: {}",
                ref.day(), ref.wp().getOrder(), ex != null ? ex.getMessage() : "");
        return new WaypointPricing(
                nm,
                ref.day(),
                ref.wp().getOrder(),
                null,
                null,
                null,
                false,
                WaypointPricingStatus.NO_MATCH,
                null);
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
