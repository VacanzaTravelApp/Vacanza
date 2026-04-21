package com.vacanza.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Request body for {@code POST /chat/routes/from-polygon}.
 * {@code coordinates} is the outer ring of a GeoJSON Polygon: each entry is [longitude, latitude].
 * The ring may be closed (first point equals last) or open.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PolygonRouteRequest {

    /**
     * Outer ring: at least 3 distinct positions; max vertices enforced server-side.
     */
    private List<List<Double>> coordinates;

    /**
     * Trip length in days (1–16).
     */
    private Integer totalDays;

    /**
     * e.g. art, history, food, nature, general — passed to AI Turn2.
     */
    private String travelStyle;

    /**
     * Mapbox category keys (museum, park, …). If null/empty, a default general set is used.
     */
    private List<String> categories;

    /**
     * When null/true, the backend pulls the user's liked POIs (UserPoiFeedback.score &gt; 0)
     * and merges the ones inside the polygon into the POI pool given to the AI. When false,
     * the route is built from Mapbox results only.
     */
    private Boolean includeFavorites;
}
