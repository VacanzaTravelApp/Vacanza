package com.vacanza.backend.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.util.ArrayList;
import java.util.List;
import java.util.OptionalDouble;
import java.util.stream.Collectors;

/**
 * Simple wrapper around Mapbox Directions API to turn waypoints into
 * a road-following polyline for the map.
 */
@Slf4j
@Service
public class MapboxDirectionsService {

    /**
     * Reuse existing Mapbox WebClient that already appends the access token
     * and is configured with baseUrl https://api.mapbox.com.
     */
    private final WebClient mapboxWebClient;

    public MapboxDirectionsService(@Qualifier("mapboxGeocodingWebClient") WebClient mapboxWebClient) {
        this.mapboxWebClient = mapboxWebClient;
    }

    public RouteGeometry getRouteGeometry(List<Waypoint> waypoints) {
        if (waypoints == null || waypoints.size() < 2) {
            throw new IllegalArgumentException("At least 2 waypoints are required");
        }

        String coords = waypoints.stream()
                .map(w -> w.longitude() + "," + w.latitude()) // Mapbox expects lon,lat
                .collect(Collectors.joining(";"));

        // Use walking profile so routes follow pedestrian paths instead of car roads.
        String path = "/directions/v5/mapbox/walking/" + coords;

        // We request GeoJSON so frontend can easily consume coordinates.
        // exclude=ferry: walking routes must never route via ferries/boats — same-day
        // stops that require a water crossing should be on separate days (enforced by
        // the geographic clustering rules). Without this, Mapbox suggests e.g. the
        // Bosphorus coastal ferry between Sarıyer and Eminönü as a "walking" connection.
        String uri = path + "?geometries=geojson&overview=full&exclude=ferry";

        MapboxDirectionsResponse response;
        try {
            response = mapboxWebClient
                    .get()
                    .uri(uri)
                    .retrieve()
                    .bodyToMono(MapboxDirectionsResponse.class)
                    .block();
        } catch (WebClientResponseException e) {
            log.warn("Mapbox directions error {} {}: {}", e.getRawStatusCode(), e.getStatusText(), e.getResponseBodyAsString());
            throw e;
        }

        if (response == null || response.routes == null || response.routes.isEmpty()) {
            throw new IllegalStateException("No route returned from Mapbox Directions");
        }

        MapboxRoute first = response.routes.get(0);
        if (first.geometry == null || first.geometry.coordinates == null || first.geometry.coordinates.isEmpty()) {
            throw new IllegalStateException("Route has no geometry");
        }

        List<Coordinate> coordsOut = new ArrayList<>();
        for (List<Double> coord : first.geometry.coordinates) {
            if (coord == null || coord.size() < 2) continue;
            double lon = coord.get(0);
            double lat = coord.get(1);
            coordsOut.add(new Coordinate(lat, lon));
        }

        return new RouteGeometry(coordsOut, first.distance, first.duration);
    }

    /**
     * Walking duration in seconds between two points (single leg). Empty if the API fails.
     */
    public OptionalDouble getWalkingDurationSeconds(double lat1, double lon1, double lat2, double lon2) {
        try {
            RouteGeometry g = getRouteGeometry(List.of(
                    new Waypoint(lat1, lon1),
                    new Waypoint(lat2, lon2)));
            if (g.duration() > 0) {
                return OptionalDouble.of(g.duration());
            }
        } catch (Exception e) {
            log.debug("Walking duration lookup failed: {}", e.getMessage());
        }
        return OptionalDouble.empty();
    }

    // ---- DTOs / Records ----

    public record Waypoint(double latitude, double longitude) {}

    public record Coordinate(double latitude, double longitude) {}

    public record RouteGeometry(List<Coordinate> coordinates, double distance, double duration) {}

    // Internal mapping of Mapbox JSON
    private static class MapboxDirectionsResponse {
        public List<MapboxRoute> routes;
    }

    private static class MapboxRoute {
        public Geometry geometry;
        public double distance;
        public double duration;
    }

    private static class Geometry {
        public String type;
        public List<List<Double>> coordinates;
    }
}

