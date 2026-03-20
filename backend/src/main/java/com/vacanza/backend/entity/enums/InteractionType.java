package com.vacanza.backend.entity.enums;

public enum InteractionType {
    AREA_SELECT,
    MAP_AREA_SEARCH,
    MAP_VIEWPORT_SEARCH,
    POI_VIEW,
    POI_FAVORITE,
    CATEGORY_FILTER,
    POI_TEXT_SEARCH;

    /** API'den gelen "area_select", "poi_view" vb. string'i enum'a çevirir. */
    public static InteractionType fromApi(String value) {
        if (value == null || value.isBlank()) return null;
        String normalized = value.toUpperCase().replace("-", "_");
        try {
            return valueOf(normalized);
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
