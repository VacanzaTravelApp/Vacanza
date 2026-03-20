package com.vacanza.backend.controller;

import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.dto.internal.PoiSearchRequest;
import com.vacanza.backend.integration.MapboxPoiSearchClient;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/internal/poi-search")
@RequiredArgsConstructor
public class PoiSearchController {

    private final MapboxPoiSearchClient mapboxPoiSearchClient;

    @PostMapping
    public ResponseEntity<List<PoiResult>> searchPois(
            @RequestBody PoiSearchRequest request) {
        if (request == null || request.getDestination() == null || request.getDestination().isBlank()) {
            return ResponseEntity.badRequest().body(List.of());
        }

        var destOpt = mapboxPoiSearchClient.geocodeDestination(request.getDestination()).blockOptional();
        if (destOpt.isEmpty()) {
            return ResponseEntity.ok(List.of());
        }

        var dest = destOpt.get();
        List<String> categories = request.getCategories() == null ? List.of() : request.getCategories();

        List<PoiResult> all = new ArrayList<>();
        for (String c : categories) {
            if (c == null || c.isBlank()) continue;
            List<PoiResult> pois = mapboxPoiSearchClient
                    .searchByCategory(c, dest.getMinLon(), dest.getMinLat(), dest.getMaxLon(), dest.getMaxLat())
                    .blockOptional()
                    .orElse(List.of());
            all.addAll(pois);
        }

        // Deduplicate by name (case-insensitive), keep first
        Map<String, PoiResult> dedup = all.stream()
                .filter(p -> p.getName() != null && !p.getName().isBlank())
                .collect(Collectors.toMap(
                        p -> p.getName().toLowerCase(Locale.ROOT),
                        p -> p,
                        (a, b) -> a
                ));

        return ResponseEntity.ok(new ArrayList<>(dedup.values()));
    }
}

