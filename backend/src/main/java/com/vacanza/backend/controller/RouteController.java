package com.vacanza.backend.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.AiRouteService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/routes")
@RequiredArgsConstructor
public class RouteController {

    private final AiRouteService aiRouteService;
    private final CurrentUserProvider currentUserProvider;
    private final ObjectMapper objectMapper;

    record RouteListItem(
            UUID routeId,
            String title,
            String destination,
            int totalDays,
            LocalDateTime generatedAt
    ) {}

    record RouteDetail(
            UUID routeId,
            String title,
            String destination,
            int totalDays,
            JsonNode routeData,
            LocalDateTime generatedAt
    ) {}

    @GetMapping
    public ResponseEntity<List<RouteListItem>> listRoutes() {
        User user = currentUserProvider.getCurrentUserEntity();
        List<RouteListItem> items = aiRouteService.getUserRoutes(user).stream()
                .map(r -> new RouteListItem(
                        r.getRouteId(), r.getTitle(), r.getDestination(),
                        r.getTotalDays(), r.getGeneratedAt()))
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
        List<RouteDetail> list = aiRouteService.getRoutesForConversation(user, conversationId).stream()
                .map(this::toDetail)
                .toList();
        return ResponseEntity.ok(list);
    }

    @GetMapping("/{routeId}")
    public ResponseEntity<RouteDetail> getRoute(@PathVariable UUID routeId) {
        User user = currentUserProvider.getCurrentUserEntity();
        return aiRouteService.getRoute(routeId, user)
                .map(r -> ResponseEntity.ok(toDetail(r)))
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

    private RouteDetail toDetail(AiRoute route) {
        JsonNode parsed;
        try {
            parsed = objectMapper.readTree(route.getRouteJson());
        } catch (Exception e) {
            log.warn("Failed to parse routeJson for route {}: {}", route.getRouteId(), e.getMessage());
            parsed = objectMapper.nullNode();
        }
        return new RouteDetail(
                route.getRouteId(), route.getTitle(), route.getDestination(),
                route.getTotalDays(), parsed, route.getGeneratedAt());
    }
}
