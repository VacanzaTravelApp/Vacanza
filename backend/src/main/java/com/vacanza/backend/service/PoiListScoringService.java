package com.vacanza.backend.service;

import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.OptionalDouble;

/**
 * Applies {@link PoiScoreCalculator} to a list: optional filtering (avoid DROP), sets {@link PoiResult#setRelevanceScore},
 * sorts by descending relevance.
 */
@Service
@RequiredArgsConstructor
public class PoiListScoringService {

    private final PoiScoreCalculator poiScoreCalculator;

    /**
     * Scores each POI, removes dropped items when avoid policy is DROP, sets relevanceScore, sorts best-first.
     */
    public List<PoiResult> scoreSortAndFilter(List<PoiResult> pois, UserProfileForAi profile) {
        if (pois == null || pois.isEmpty()) {
            return pois == null ? List.of() : pois;
        }
        List<PoiResult> out = new ArrayList<>();
        for (PoiResult p : pois) {
            OptionalDouble s = poiScoreCalculator.score(p, profile);
            if (s.isEmpty()) {
                continue;
            }
            p.setRelevanceScore(s.getAsDouble());
            out.add(p);
        }
        out.sort(Comparator.comparingDouble((PoiResult x) -> x.getRelevanceScore() != null ? x.getRelevanceScore() : 0.0)
                .reversed());
        return out;
    }
}
