package com.vacanza.backend.controller;

import com.vacanza.backend.dto.response.WaypointPricing;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.ViatorPricingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Viator Partner API pricing for saved AI routes (Firebase-authenticated).
 */
@RestController
@RequestMapping("/routes")
@RequiredArgsConstructor
public class ViatorPricingController {

    private final ViatorPricingService viatorPricingService;
    private final CurrentUserProvider currentUserProvider;

    /**
     * Best-effort Viator prices per waypoint. {@code found=false} when there is no catalog match.
     * Route must belong to the caller; otherwise HTTP 404.
     */
    @GetMapping("/{routeId}/pricing")
    public ResponseEntity<List<WaypointPricing>> getPricing(@PathVariable UUID routeId) {
        return viatorPricingService.loadPricing(routeId, currentUserProvider.getCurrentUserEntity())
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
