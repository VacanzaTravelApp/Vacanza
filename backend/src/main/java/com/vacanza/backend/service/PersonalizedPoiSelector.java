package com.vacanza.backend.service;

import com.vacanza.backend.config.PoiDiversityProperties;
import com.vacanza.backend.config.PoiScoringProperties;
import com.vacanza.backend.dto.internal.PoiCategoryFamily;
import com.vacanza.backend.dto.internal.PersonalizedPoiParams;
import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.dto.internal.PoiRetrievalContext;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Tags;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

/**
 * Single entry for post-search POI personalization: enrich → avoid (DROP) → score → constraints → diversity → LLM cap.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PersonalizedPoiSelector {

    private final PoiResultEnrichmentService enrichmentService;
    private final PoiScoringProperties scoringProperties;
    private final PoiListScoringService listScoringService;
    private final PoiConstraintFilter constraintFilter;
    private final PoiDiversitySelector diversitySelector;
    private final PoiDiversityProperties diversityProperties;
    private final ObjectProvider<MeterRegistry> meterRegistry;

    /**
     * @param rawPois deduplicated Mapbox rows (not yet enriched)
     */
    public List<PoiResult> select(List<PoiResult> rawPois, UserProfileForAi profile, PersonalizedPoiParams params) {
        PersonalizedPoiParams p = params != null ? params : PersonalizedPoiParams.defaults();
        PoiRetrievalContext ctx = p.retrievalContext() != null ? p.retrievalContext() : PoiRetrievalContext.empty();

        List<PoiResult> enriched = enrichmentService.enrichAll(rawPois == null ? List.of() : new ArrayList<>(rawPois));
        List<PoiResult> afterAvoid = filterAvoidDrop(enriched, profile);
        List<PoiResult> scored = listScoringService.scoreSortAndFilter(afterAvoid, profile);
        List<PoiResult> constrained = constraintFilter.apply(scored, profile, ctx);
        List<PoiResult> diversified = diversitySelector.diversify(constrained);
        int cap = Math.max(1, p.maxForLlm() != null ? p.maxForLlm() : diversityProperties.getTargetCount());
        List<PoiResult> out = truncate(diversified, cap);

        logAndMetrics(out);
        return out;
    }

    /**
     * When {@link PoiScoringProperties.AvoidMode#DROP}, remove POIs matching {@code avoidCategories} before scoring.
     * PENALTY mode keeps all rows; scoring applies the penalty.
     */
    private List<PoiResult> filterAvoidDrop(List<PoiResult> pois, UserProfileForAi profile) {
        if (pois == null || pois.isEmpty()) {
            return pois == null ? List.of() : pois;
        }
        if (profile == null
                || profile.getAvoidCategories() == null
                || profile.getAvoidCategories().isEmpty()
                || scoringProperties.getAvoidMode() != PoiScoringProperties.AvoidMode.DROP) {
            return new ArrayList<>(pois);
        }
        List<PoiResult> out = new ArrayList<>();
        for (PoiResult poi : pois) {
            if (!PoiPreferenceMatcher.matchesAnyToken(poi, profile.getAvoidCategories())) {
                out.add(poi);
            }
        }
        return out;
    }

    private static List<PoiResult> truncate(List<PoiResult> list, int max) {
        if (list.size() <= max) {
            return list;
        }
        return new ArrayList<>(list.subList(0, max));
    }

    private void logAndMetrics(List<PoiResult> out) {
        Map<PoiCategoryFamily, Integer> dist = new EnumMap<>(PoiCategoryFamily.class);
        for (PoiCategoryFamily f : PoiCategoryFamily.values()) {
            dist.put(f, 0);
        }
        for (PoiResult r : out) {
            PoiCategoryFamily f = r.getCategoryFamily() != null ? r.getCategoryFamily() : PoiCategoryFamily.OTHER;
            dist.merge(f, 1, Integer::sum);
        }
        if (log.isDebugEnabled()) {
            log.debug("personalized_poi familyDistribution={} size={}", dist, out.size());
        }
        meterRegistry.ifAvailable(registry -> {
            registry.counter("vacanza.poi.personalized.output.total", Tags.of("size_bucket", sizeBucket(out.size())))
                    .increment();
            for (Map.Entry<PoiCategoryFamily, Integer> e : dist.entrySet()) {
                if (e.getValue() == 0) {
                    continue;
                }
                registry.counter(
                                "vacanza.poi.personalized.output.by_family",
                                Tags.of("family", e.getKey().name()))
                        .increment(e.getValue());
            }
        });
    }

    private static String sizeBucket(int n) {
        if (n <= 0) {
            return "0";
        }
        if (n <= 15) {
            return "1-15";
        }
        if (n <= 30) {
            return "16-30";
        }
        if (n <= 60) {
            return "31-60";
        }
        return "61+";
    }
}
