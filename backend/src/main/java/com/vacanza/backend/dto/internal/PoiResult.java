package com.vacanza.backend.dto.internal;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

/**
 * POI row from Mapbox Search Box (and optional DB enrichment) for agentic itinerary tool results.
 * Optional fields are null when unknown or not provided by the upstream API.
 */
@Data
@NoArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class PoiResult {

    private String name;
    private String category;
    private double lat;
    private double lon;

    /** Business / aggregate rating when available (e.g. from DB). Mapbox category response does not include rating. */
    private Double rating;
    /** Review count or popularity proxy; null if unknown. */
    private Double reviewCount;
    private String priceLevel;

    /**
     * Mapbox Search Box stable feature id (see {@code properties.mapbox_id} in category response).
     */
    private String mapboxId;

    /**
     * External id usable for DB join — typically Foursquare id when present in {@link #externalIds}.
     */
    private String externalId;

    private Integer estimatedDurationMin;

    /**
     * When true (default for Mapbox-only rows), opening hours are not known.
     * DB enrichment may set {@link #startTimeLocal}/{@link #endTimeLocal} and clear this flag.
     */
    private Boolean openingHoursUnknown;

    /** Local time-of-day strings "HH:mm" when known (from DB). */
    private String startTimeLocal;
    private String endTimeLocal;

    /** Mapbox Maki icon id when present. */
    private String maki;

    /** Canonical POI category ids from Mapbox ({@code poi_category_ids}). */
    private List<String> poiCategoryIds;

    /** e.g. foursquare → id; values are string ids. */
    private Map<String, String> externalIds;

    /** Derived coarse family for diversity / scoring (Faz A). */
    private PoiCategoryFamily categoryFamily;

    /**
     * Profile-based relevance after {@link com.vacanza.backend.service.PoiListScoringService} (Faz B); null before scoring.
     */
    private Double relevanceScore;

    /**
     * Minimal constructor used by Mapbox client; optional fields default to unknown opening hours.
     */
    public PoiResult(String name, String category, double lat, double lon) {
        this.name = name;
        this.category = category;
        this.lat = lat;
        this.lon = lon;
        this.openingHoursUnknown = true;
    }
}
