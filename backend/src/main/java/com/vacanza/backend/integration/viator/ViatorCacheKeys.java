package com.vacanza.backend.integration.viator;

import java.util.Locale;
import java.util.UUID;

/**
 * Normalized cache keys: {@code attraction:{id}} or {@code dest:{destinationId}:wp:{hash}}.
 */
public final class ViatorCacheKeys {

    private ViatorCacheKeys() {
    }

    /**
     * Per-route waypoint cache key (same route + day + order + normalized name).
     */
    public static String routeWaypoint(UUID routeId, int day, int order, String waypointName) {
        String n = waypointName == null ? "" : waypointName.trim().toLowerCase(Locale.ROOT);
        return "route:" + routeId + ":d" + day + ":o" + order + ":n:" + n;
    }

    public static String attraction(long attractionId) {
        return "attraction:" + attractionId;
    }

    /**
     * @param waypointHash stable hash or id for the map waypoint (trimmed, lowercased)
     */
    public static String destinationWaypoint(long destinationId, String waypointHash) {
        String h = waypointHash == null ? "" : waypointHash.trim().toLowerCase(Locale.ROOT);
        return "dest:" + destinationId + ":wp:" + h;
    }
}
