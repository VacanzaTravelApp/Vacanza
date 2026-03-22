package com.vacanza.backend.service;

import com.vacanza.backend.dto.internal.PoiCategoryFamily;
import com.vacanza.backend.dto.internal.PoiResult;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Maps search category + optional Mapbox {@code poi_category_ids} to a coarse {@link PoiCategoryFamily}.
 */
@Component
public class PoiCategoryFamilyResolver {

    private static final Set<String> CULTURE = Set.of(
            "museum", "art_gallery", "gallery", "historic_site", "heritage", "monument", "ruins",
            "landmark", "palace", "castle", "archaeological_site", "historic");
    private static final Set<String> FOOD = Set.of(
            "restaurant", "cafe", "market", "bistro", "bakery", "food", "bar", "winery", "coffee_shop");
    private static final Set<String> OUTDOOR = Set.of(
            "park", "national_park", "nature_reserve", "beach", "garden");
    private static final Set<String> AREA = Set.of(
            "neighborhood", "district", "quarter");
    private static final Set<String> WORSHIP = Set.of(
            "church", "mosque", "place_of_worship", "synagogue", "temple", "shrine", "cathedral", "chapel");
    private static final Set<String> SHOPPING = Set.of(
            "shopping_mall", "department_store", "shopping_center", "market");
    private static final Set<String> ENTERTAINMENT = Set.of(
            "amusement_park", "theme_park", "water_park", "zoo", "aquarium", "wildlife_park", "nightlife");
    private static final Set<String> TRANSPORT = Set.of(
            "bridge", "pier", "viewpoint", "observation_deck");

    public void assignFamily(PoiResult p) {
        if (p == null) {
            return;
        }
        p.setCategoryFamily(resolve(p.getCategory(), p.getPoiCategoryIds()));
    }

    public PoiCategoryFamily resolve(String searchCategory, List<String> poiCategoryIds) {
        PoiCategoryFamily fromIds = resolveFromTokens(poiCategoryIds);
        if (fromIds != null) {
            return fromIds;
        }
        return resolveFromSingleCategory(searchCategory);
    }

    private static PoiCategoryFamily resolveFromTokens(List<String> ids) {
        if (ids == null || ids.isEmpty()) {
            return null;
        }
        for (String raw : ids) {
            if (raw == null || raw.isBlank()) {
                continue;
            }
            String t = raw.toLowerCase(Locale.ROOT).replace('-', '_');
            PoiCategoryFamily f = classifyToken(t);
            if (f != null) {
                return f;
            }
        }
        return null;
    }

    private static PoiCategoryFamily resolveFromSingleCategory(String category) {
        if (category == null || category.isBlank()) {
            return PoiCategoryFamily.OTHER;
        }
        String t = category.toLowerCase(Locale.ROOT).replace('-', '_');
        PoiCategoryFamily f = classifyToken(t);
        return f != null ? f : PoiCategoryFamily.OTHER;
    }

    /**
     * First matching family wins (order follows enum rough priority).
     */
    private static PoiCategoryFamily classifyToken(String t) {
        if (matchesAny(t, CULTURE)) {
            return PoiCategoryFamily.CULTURE;
        }
        if (matchesAny(t, FOOD)) {
            return PoiCategoryFamily.FOOD;
        }
        if (matchesAny(t, ENTERTAINMENT)) {
            return PoiCategoryFamily.ENTERTAINMENT;
        }
        if (matchesAny(t, WORSHIP)) {
            return PoiCategoryFamily.WORSHIP;
        }
        if (matchesAny(t, SHOPPING)) {
            return PoiCategoryFamily.SHOPPING;
        }
        if (matchesAny(t, OUTDOOR)) {
            return PoiCategoryFamily.OUTDOOR;
        }
        if (matchesAny(t, AREA)) {
            return PoiCategoryFamily.AREA;
        }
        if (matchesAny(t, TRANSPORT)) {
            return PoiCategoryFamily.TRANSPORT;
        }
        return null;
    }

    private static boolean matchesAny(String token, Set<String> set) {
        if (set.contains(token)) {
            return true;
        }
        for (String s : set) {
            if (token.contains(s) || s.contains(token)) {
                return true;
            }
        }
        return false;
    }
}
