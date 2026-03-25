package com.vacanza.backend.integration.viator;

import java.util.Locale;

/**
 * Normalized cache keys: {@code attraction:{id}} or {@code dest:{destinationId}:wp:{hash}}.
 */
public final class ViatorCacheKeys {

    private ViatorCacheKeys() {
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
