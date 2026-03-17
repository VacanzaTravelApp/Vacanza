package com.vacanza.backend.controller;

import com.vacanza.backend.service.MapboxDirectionsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Exposes a simple endpoint to turn a list of waypoints into
 * a road-following polyline using Mapbox Directions.
 */
@RestController
@RequestMapping("/routes/directions")
@RequiredArgsConstructor
public class RouteDirectionsController {

    private final MapboxDirectionsService directionsService;

    public record WaypointDto(double latitude, double longitude) {}

    public record RouteGeometryRequest(List<WaypointDto> waypoints) {}

    public record CoordinateDto(double latitude, double longitude) {}

    public record RouteGeometryResponse(List<CoordinateDto> coordinates, double distance, double duration) {}

    @PostMapping
    public ResponseEntity<RouteGeometryResponse> getRouteGeometry(@RequestBody RouteGeometryRequest request) {
        if (request == null || request.waypoints() == null || request.waypoints().size() < 2) {
            return ResponseEntity.badRequest().build();
        }

        var waypoints = request.waypoints().stream()
                .map(w -> new MapboxDirectionsService.Waypoint(w.latitude(), w.longitude()))
                .toList();

        var geometry = directionsService.getRouteGeometry(waypoints);

        var coordinates = geometry.coordinates().stream()
                .map(c -> new CoordinateDto(c.latitude(), c.longitude()))
                .toList();

        return ResponseEntity.ok(new RouteGeometryResponse(coordinates, geometry.distance(), geometry.duration()));
    }
}

