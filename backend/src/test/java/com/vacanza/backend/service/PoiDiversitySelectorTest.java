package com.vacanza.backend.service;

import com.vacanza.backend.config.PoiDiversityProperties;
import com.vacanza.backend.dto.internal.PoiCategoryFamily;
import com.vacanza.backend.dto.internal.PoiResult;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class PoiDiversitySelectorTest {

    @Test
    void mmr_prefers_diverse_second_pick_when_lambda_balanced() {
        PoiDiversityProperties props = new PoiDiversityProperties();
        props.setEnabled(true);
        props.setMode(PoiDiversityProperties.DiversityMode.MMR);
        props.setTargetCount(3);
        props.setPoolSize(20);
        props.setMmrLambda(0.5);
        PoiDiversitySelector sel = new PoiDiversitySelector(props);

        List<PoiResult> in = new ArrayList<>();
        PoiResult m1 = new PoiResult("M1", "museum", 41.0, 29.0);
        m1.setCategoryFamily(PoiCategoryFamily.CULTURE);
        m1.setRelevanceScore(10.0);
        in.add(m1);
        PoiResult m2 = new PoiResult("M2", "museum", 41.01, 29.01);
        m2.setCategoryFamily(PoiCategoryFamily.CULTURE);
        m2.setRelevanceScore(9.9);
        in.add(m2);
        PoiResult park = new PoiResult("Park", "park", 41.1, 29.1);
        park.setCategoryFamily(PoiCategoryFamily.OUTDOOR);
        park.setRelevanceScore(9.0);
        in.add(park);

        List<PoiResult> out = sel.diversify(in);
        assertEquals(3, out.size());
        assertEquals("M1", out.get(0).getName());
        assertEquals("Park", out.get(1).getName());
    }

    @Test
    void family_cap_respects_max_per_family_in_first_pass() {
        PoiDiversityProperties props = new PoiDiversityProperties();
        props.setEnabled(true);
        props.setMode(PoiDiversityProperties.DiversityMode.FAMILY_CAP);
        props.setTargetCount(5);
        props.setPoolSize(30);
        props.setMaxPerFamily(2);
        PoiDiversitySelector sel = new PoiDiversitySelector(props);

        List<PoiResult> in = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            PoiResult p = new PoiResult("M" + i, "museum", 41.0 + i * 0.001, 29.0);
            p.setCategoryFamily(PoiCategoryFamily.CULTURE);
            p.setRelevanceScore(10.0 - i);
            in.add(p);
        }
        PoiResult park = new PoiResult("P0", "park", 40.0, 28.0);
        park.setCategoryFamily(PoiCategoryFamily.OUTDOOR);
        park.setRelevanceScore(1.0);
        in.add(park);

        List<PoiResult> out = sel.diversify(in);
        assertEquals(5, out.size());
        long culture = out.stream().filter(p -> p.getCategoryFamily() == PoiCategoryFamily.CULTURE).count();
        assertEquals(4, culture);
    }

    @Test
    void disabled_truncates_only() {
        PoiDiversityProperties props = new PoiDiversityProperties();
        props.setEnabled(false);
        props.setTargetCount(3);
        PoiDiversitySelector sel = new PoiDiversitySelector(props);

        List<PoiResult> in = List.of(
                poi("a", 1.0),
                poi("b", 2.0),
                poi("c", 3.0),
                poi("d", 4.0)
        );
        List<PoiResult> out = sel.diversify(in);
        assertEquals(3, out.size());
        assertEquals("a", out.get(0).getName());
    }

    private static PoiResult poi(String name, double score) {
        PoiResult p = new PoiResult(name, "landmark", 41, 29);
        p.setRelevanceScore(score);
        p.setCategoryFamily(PoiCategoryFamily.OTHER);
        return p;
    }
}
