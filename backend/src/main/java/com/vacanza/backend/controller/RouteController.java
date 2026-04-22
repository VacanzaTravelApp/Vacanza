package com.vacanza.backend.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.dto.request.RouteHotelRequestDTO;
import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.RouteHotel;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.enums.RouteFeedbackVote;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.AiRouteService;
import com.vacanza.backend.service.UserRouteFeedbackService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/routes")
@RequiredArgsConstructor
public class RouteController {

    private final AiRouteService aiRouteService;
    private final CurrentUserProvider currentUserProvider;
    private final UserRouteFeedbackService userRouteFeedbackService;
    private final ObjectMapper objectMapper;

    record RouteListItem(
            UUID routeId,
            String title,
            String destination,
            int totalDays,
            LocalDateTime generatedAt,
            /** "UP", "DOWN", or null */
            String userFeedback
    ) {}

    record RouteHotelView(
            String hotelName,
            String hotelExternalId,
            String address,
            Double latitude,
            Double longitude,
            String imageUrl,
            String externalBookingUrl,
            BigDecimal pricePerNight,
            String currency,
            Double rating,
            String providerName
    ) {}

    record RouteDetail(
            UUID routeId,
            String title,
            String destination,
            int totalDays,
            JsonNode routeData,
            LocalDateTime generatedAt,
            /** "UP", "DOWN", or null */
            String userFeedback,
            RouteHotelView selectedHotel
    ) {}

    @GetMapping
    public ResponseEntity<List<RouteListItem>> listRoutes() {
        User user = currentUserProvider.getCurrentUserEntity();
        List<AiRoute> routes = aiRouteService.getUserRoutes(user);
        Map<UUID, RouteFeedbackVote> votes = userRouteFeedbackService.findVotesForUserAndRoutes(
                user.getUserId(),
                routes.stream().map(AiRoute::getRouteId).toList());
        List<RouteListItem> items = routes.stream()
                .map(r -> new RouteListItem(
                        r.getRouteId(), r.getTitle(), r.getDestination(),
                        r.getTotalDays(), r.getGeneratedAt(),
                        feedbackString(votes, r.getRouteId())))
                .toList();
        return ResponseEntity.ok(items);
    }

    /**
     * All saved routes for this chat, oldest first (user-scoped). Restores route cards in thread order.
     */
    @GetMapping("/conversation/{conversationId}")
    public ResponseEntity<List<RouteDetail>> getRoutesForConversation(
            @PathVariable UUID conversationId) {
        User user = currentUserProvider.getCurrentUserEntity();
        List<AiRoute> routes = aiRouteService.getRoutesForConversation(user, conversationId);
        Map<UUID, RouteFeedbackVote> votes = userRouteFeedbackService.findVotesForUserAndRoutes(
                user.getUserId(),
                routes.stream().map(AiRoute::getRouteId).toList());
        List<RouteDetail> list = routes.stream()
                .map(r -> toDetail(r, votes))
                .toList();
        return ResponseEntity.ok(list);
    }

    @GetMapping("/{routeId}")
    public ResponseEntity<RouteDetail> getRoute(@PathVariable UUID routeId) {
        User user = currentUserProvider.getCurrentUserEntity();
        return aiRouteService.getRoute(routeId, user)
                .map(r -> ResponseEntity.ok(toDetail(r, user)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{routeId}")
    public ResponseEntity<Void> deleteRoute(@PathVariable UUID routeId) {
        User user = currentUserProvider.getCurrentUserEntity();
        if (aiRouteService.getRoute(routeId, user).isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        aiRouteService.deleteRoute(routeId, user);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{routeId}/hotel")
    public ResponseEntity<RouteDetail> setHotel(
            @PathVariable UUID routeId,
            @RequestBody RouteHotelRequestDTO dto) {
        User user = currentUserProvider.getCurrentUserEntity();
        return aiRouteService.setRouteHotel(routeId, user, dto)
                .map(r -> ResponseEntity.ok(toDetail(r, user)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{routeId}/hotel")
    public ResponseEntity<RouteDetail> removeHotel(@PathVariable UUID routeId) {
        User user = currentUserProvider.getCurrentUserEntity();
        return aiRouteService.removeRouteHotel(routeId, user)
                .map(r -> ResponseEntity.ok(toDetail(r, user)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    private RouteDetail toDetail(AiRoute route, User user) {
        Map<UUID, RouteFeedbackVote> votes = userRouteFeedbackService.findVotesForUserAndRoutes(
                user.getUserId(), List.of(route.getRouteId()));
        return toDetail(route, votes);
    }

    private RouteDetail toDetail(AiRoute route, Map<UUID, RouteFeedbackVote> votes) {
        JsonNode parsed;
        try {
            parsed = objectMapper.readTree(route.getRouteJson());
        } catch (Exception e) {
            log.warn("Failed to parse routeJson for route {}: {}", route.getRouteId(), e.getMessage());
            parsed = objectMapper.nullNode();
        }
        return new RouteDetail(
                route.getRouteId(), route.getTitle(), route.getDestination(),
                route.getTotalDays(), parsed, route.getGeneratedAt(),
                feedbackString(votes, route.getRouteId()),
                toHotelView(route.getSelectedHotel()));
    }

    private RouteHotelView toHotelView(RouteHotel hotel) {
        if (hotel == null || hotel.getHotelName() == null) return null;
        return new RouteHotelView(
                hotel.getHotelName(), hotel.getHotelExternalId(), hotel.getAddress(),
                hotel.getLatitude(), hotel.getLongitude(), hotel.getImageUrl(),
                hotel.getExternalBookingUrl(), hotel.getPricePerNight(), hotel.getCurrency(),
                hotel.getRating(), hotel.getProviderName());
    }

    private static String feedbackString(Map<UUID, RouteFeedbackVote> votes, UUID routeId) {
        RouteFeedbackVote v = votes.get(routeId);
        return v == null ? null : v.toApiString();
    }
}
