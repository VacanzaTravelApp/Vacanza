package com.vacanza.backend.integration;

import com.vacanza.backend.dto.internal.PoiCategoryFamily;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * Maps Foursquare numeric category IDs to our internal {@link PoiCategoryFamily}
 * and a human-readable subcategory string (cuisine / place type).
 *
 * <p>Foursquare category taxonomy reference:
 * https://docs.foursquare.com/developer/reference/place-categories
 *
 * <p>Only the most common categories for travel itineraries are listed.
 * Unknown IDs fall back to the parent-level resolution or OTHER.
 */
@Component
public class FoursquareCategoryMapper {

    // ─── Foursquare ID → subcategory label ───────────────────────────────────

    private static final Map<Integer, String> SUBCATEGORY = Map.ofEntries(
            // Restaurants
            Map.entry(13065, "restaurant"),
            Map.entry(13064, "italian_restaurant"),
            Map.entry(13145, "burger_joint"),
            Map.entry(13314, "turkish_restaurant"),
            Map.entry(13236, "seafood_restaurant"),
            Map.entry(13285, "pizza_restaurant"),
            Map.entry(13193, "kebab_restaurant"),
            Map.entry(13187, "japanese_restaurant"),
            Map.entry(13149, "chinese_restaurant"),
            Map.entry(13340, "vegetarian"),
            Map.entry(13276, "meze_restaurant"),
            // Cafes & Coffee
            Map.entry(13032, "cafe"),
            Map.entry(13033, "coffee_roaster"),
            Map.entry(13035, "espresso_bar"),
            Map.entry(13034, "coffee_shop"),
            // Bakeries & Desserts
            Map.entry(13002, "bakery"),
            Map.entry(13040, "pastry_shop"),
            Map.entry(13055, "dessert_shop"),
            // Bars
            Map.entry(13003, "bar"),
            Map.entry(13009, "cocktail_bar"),
            Map.entry(13017, "wine_bar"),
            // Markets & Street Food
            Map.entry(13068, "food_market"),
            Map.entry(13338, "street_food"),
            // Culture
            Map.entry(10000, "museum"),
            Map.entry(10027, "art_gallery"),
            Map.entry(10004, "historic_site"),
            Map.entry(10024, "landmark"),
            // Outdoors
            Map.entry(16032, "park"),
            Map.entry(16019, "beach"),
            Map.entry(16011, "garden"),
            // Shopping
            Map.entry(17114, "market"),
            Map.entry(17069, "department_store"),
            // Entertainment
            Map.entry(18008, "nightclub"),
            Map.entry(19014, "amusement_park")
    );

    // ─── Foursquare ID → PoiCategoryFamily ───────────────────────────────────

    private static final Map<Integer, PoiCategoryFamily> FAMILY = Map.ofEntries(
            Map.entry(13065, PoiCategoryFamily.FOOD),
            Map.entry(13064, PoiCategoryFamily.FOOD),
            Map.entry(13145, PoiCategoryFamily.FOOD),
            Map.entry(13314, PoiCategoryFamily.FOOD),
            Map.entry(13236, PoiCategoryFamily.FOOD),
            Map.entry(13285, PoiCategoryFamily.FOOD),
            Map.entry(13193, PoiCategoryFamily.FOOD),
            Map.entry(13187, PoiCategoryFamily.FOOD),
            Map.entry(13149, PoiCategoryFamily.FOOD),
            Map.entry(13340, PoiCategoryFamily.FOOD),
            Map.entry(13276, PoiCategoryFamily.FOOD),
            Map.entry(13032, PoiCategoryFamily.FOOD),
            Map.entry(13033, PoiCategoryFamily.FOOD),
            Map.entry(13035, PoiCategoryFamily.FOOD),
            Map.entry(13034, PoiCategoryFamily.FOOD),
            Map.entry(13002, PoiCategoryFamily.FOOD),
            Map.entry(13040, PoiCategoryFamily.FOOD),
            Map.entry(13055, PoiCategoryFamily.FOOD),
            Map.entry(13003, PoiCategoryFamily.FOOD),
            Map.entry(13009, PoiCategoryFamily.FOOD),
            Map.entry(13017, PoiCategoryFamily.FOOD),
            Map.entry(13068, PoiCategoryFamily.FOOD),
            Map.entry(13338, PoiCategoryFamily.FOOD),
            Map.entry(10000, PoiCategoryFamily.CULTURE),
            Map.entry(10027, PoiCategoryFamily.CULTURE),
            Map.entry(10004, PoiCategoryFamily.CULTURE),
            Map.entry(10024, PoiCategoryFamily.CULTURE),
            Map.entry(16032, PoiCategoryFamily.OUTDOOR),
            Map.entry(16019, PoiCategoryFamily.OUTDOOR),
            Map.entry(16011, PoiCategoryFamily.OUTDOOR),
            Map.entry(17114, PoiCategoryFamily.SHOPPING),
            Map.entry(17069, PoiCategoryFamily.SHOPPING),
            Map.entry(18008, PoiCategoryFamily.ENTERTAINMENT),
            Map.entry(19014, PoiCategoryFamily.ENTERTAINMENT)
    );

    /**
     * Resolves the best {@link PoiCategoryFamily} from a Foursquare categories list.
     * First matching category wins.
     *
     * @return resolved family, or {@code null} if no match (caller should keep existing value)
     */
    public PoiCategoryFamily resolveFamily(List<FoursquareClient.FsqCategory> categories) {
        if (categories == null) return null;
        for (FoursquareClient.FsqCategory c : categories) {
            if (c.getId() == null) continue;
            PoiCategoryFamily f = FAMILY.get(c.getId());
            if (f != null) return f;
        }
        return null;
    }

    /**
     * Resolves the most specific subcategory label (e.g. "cafe", "turkish_restaurant").
     * First matching category wins.
     *
     * @return subcategory string, or {@code null} if no match
     */
    public String resolveSubcategory(List<FoursquareClient.FsqCategory> categories) {
        if (categories == null) return null;
        for (FoursquareClient.FsqCategory c : categories) {
            if (c.getId() == null) continue;
            String sub = SUBCATEGORY.get(c.getId());
            if (sub != null) return sub;
        }
        return null;
    }

    /**
     * Derives a cuisine/place-type label suitable for AI context from categories.
     * Uses Foursquare's {@code shortName} as first preference, then {@code name}.
     *
     * <p>Examples: "Italian", "Café", "Sushi Restaurant", "Rooftop Bar"
     *
     * @return human-readable cuisine/type string, or {@code null}
     */
    public String resolveCuisineLabel(List<FoursquareClient.FsqCategory> categories) {
        if (categories == null || categories.isEmpty()) return null;
        FoursquareClient.FsqCategory first = categories.get(0);
        if (first.getShortName() != null && !first.getShortName().isBlank()) {
            return first.getShortName();
        }
        return first.getName();
    }
}
