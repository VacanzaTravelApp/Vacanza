package com.vacanza.backend.service;

import com.vacanza.backend.dto.internal.PoiCategoryFamily;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class PoiCategoryFamilyResolverTest {

    private final PoiCategoryFamilyResolver resolver = new PoiCategoryFamilyResolver();

    @Test
    void prefers_poi_category_ids_over_search_category() {
        assertEquals(PoiCategoryFamily.FOOD,
                resolver.resolve("museum", List.of("restaurant", "food")));
    }

    @Test
    void search_category_museum_is_culture() {
        assertEquals(PoiCategoryFamily.CULTURE, resolver.resolve("museum", List.of()));
    }

    @Test
    void mosque_is_worship() {
        assertEquals(PoiCategoryFamily.WORSHIP, resolver.resolve("mosque", null));
    }
}
