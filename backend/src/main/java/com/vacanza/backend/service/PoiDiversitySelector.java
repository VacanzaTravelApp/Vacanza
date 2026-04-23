package com.vacanza.backend.service;

import com.vacanza.backend.config.PoiDiversityProperties;
import com.vacanza.backend.dto.internal.PoiCategoryFamily;
import com.vacanza.backend.dto.internal.PoiResult;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Reduces redundant POIs (same {@link PoiCategoryFamily}) in the scored, sorted list before the LLM step.
 * <p>
 * MMR: maximal marginal relevance using family overlap as similarity.<br>
 * FAMILY_CAP: greedy cap per family, then fill remaining slots by original score order.
 */
@Component
@RequiredArgsConstructor
public class PoiDiversitySelector {

    private final PoiDiversityProperties props;

    public List<PoiResult> diversify(List<PoiResult> scoreSorted) {
        if (scoreSorted == null || scoreSorted.isEmpty()) {
            return scoreSorted == null ? List.of() : scoreSorted;
        }
        if (!props.isEnabled()) {
            return truncate(scoreSorted, props.getTargetCount());
        }
        int poolLimit = Math.min(props.getPoolSize(), scoreSorted.size());
        List<PoiResult> pool = new ArrayList<>(scoreSorted.subList(0, poolLimit));
        if (pool.isEmpty()) {
            return List.of();
        }
        List<PoiResult> out = switch (props.getMode()) {
            case MMR -> mmr(pool);
            case FAMILY_CAP -> familyCap(pool);
        };
        return truncate(out, props.getTargetCount());
    }

    private static List<PoiResult> truncate(List<PoiResult> list, int max) {
        if (list.size() <= max) {
            return list;
        }
        return new ArrayList<>(list.subList(0, max));
    }

    private List<PoiResult> mmr(List<PoiResult> pool) {
        int target = Math.min(props.getTargetCount(), pool.size());
        double[] rel = normalizeRelevance(pool);
        double lambda = clampLambda(props.getMmrLambda());

        List<Integer> candidateIdx = new ArrayList<>();
        for (int i = 0; i < pool.size(); i++) {
            candidateIdx.add(i);
        }
        List<Integer> selectedIdx = new ArrayList<>();

        while (selectedIdx.size() < target && !candidateIdx.isEmpty()) {
            int bestCi = -1;
            double bestMmr = Double.NEGATIVE_INFINITY;
            for (int ci : candidateIdx) {
                double maxSim = 0.0;
                for (int si : selectedIdx) {
                    maxSim = Math.max(maxSim, familySimilarity(pool.get(ci), pool.get(si)));
                }
                double mmr = lambda * rel[ci] - (1.0 - lambda) * maxSim;
                if (mmr > bestMmr) {
                    bestMmr = mmr;
                    bestCi = ci;
                }
            }
            if (bestCi < 0) {
                break;
            }
            selectedIdx.add(bestCi);
            candidateIdx.remove(Integer.valueOf(bestCi));
        }

        List<PoiResult> out = new ArrayList<>();
        for (int i : selectedIdx) {
            out.add(pool.get(i));
        }
        return out;
    }

    private List<PoiResult> familyCap(List<PoiResult> pool) {
        int target = Math.min(props.getTargetCount(), pool.size());
        int cap = Math.max(1, props.getMaxPerFamily());

        List<PoiResult> out = new ArrayList<>();
        Map<PoiCategoryFamily, Integer> counts = new EnumMap<>(PoiCategoryFamily.class);

        for (PoiResult p : pool) {
            if (out.size() >= target) {
                break;
            }
            PoiCategoryFamily fam = family(p);
            int n = counts.getOrDefault(fam, 0);
            if (n < cap) {
                out.add(p);
                counts.put(fam, n + 1);
            }
        }

        if (out.size() < target) {
            Set<String> seen = keys(out);
            for (PoiResult p : pool) {
                if (out.size() >= target) {
                    break;
                }
                String k = key(p);
                if (seen.add(k)) {
                    out.add(p);
                }
            }
        }
        return out;
    }

    private static double clampLambda(double lambda) {
        if (lambda < 0) {
            return 0;
        }
        if (lambda > 1) {
            return 1;
        }
        return lambda;
    }

    private static double[] normalizeRelevance(List<PoiResult> pool) {
        double min = Double.POSITIVE_INFINITY;
        double max = Double.NEGATIVE_INFINITY;
        for (PoiResult p : pool) {
            double v = relevance(p);
            min = Math.min(min, v);
            max = Math.max(max, v);
        }
        double[] out = new double[pool.size()];
        if (max <= min) {
            for (int i = 0; i < pool.size(); i++) {
                out[i] = 0.5;
            }
            return out;
        }
        for (int i = 0; i < pool.size(); i++) {
            out[i] = (relevance(pool.get(i)) - min) / (max - min);
        }
        return out;
    }

    private static double relevance(PoiResult p) {
        if (p.getRelevanceScore() == null) {
            return 0.0;
        }
        return p.getRelevanceScore();
    }

    private static double familySimilarity(PoiResult a, PoiResult b) {
        return family(a) == family(b) ? 1.0 : 0.0;
    }

    private static PoiCategoryFamily family(PoiResult p) {
        return p.getCategoryFamily() != null ? p.getCategoryFamily() : PoiCategoryFamily.OTHER;
    }

    private static String key(PoiResult p) {
        return p.getName() + "|" + p.getLat() + "|" + p.getLon();
    }

    private static Set<String> keys(List<PoiResult> list) {
        Set<String> s = new HashSet<>();
        for (PoiResult p : list) {
            s.add(key(p));
        }
        return s;
    }
}
