package com.vacanza.backend.service;

import com.vacanza.backend.config.PoiFeedbackProperties;
import com.vacanza.backend.dto.enums.PoiFeedbackEventType;
import com.vacanza.backend.dto.internal.PoiFeedbackContext;
import com.vacanza.backend.dto.request.PoiFeedbackEventRequestDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserCategoryAffinity;
import com.vacanza.backend.entity.UserPoiFeedback;
import com.vacanza.backend.repo.UserCategoryAffinityRepository;
import com.vacanza.backend.repo.UserPoiFeedbackRepository;
import com.vacanza.backend.util.PoiFeedbackKeyUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserFeedbackService {

    /** Stored rows with |score| below this are removed instead of persisting zero. */
    private static final double NEUTRAL_SCORE_EPS = 1e-9;

    private final PoiFeedbackProperties props;
    private final UserPoiFeedbackRepository poiFeedbackRepository;
    private final UserCategoryAffinityRepository categoryAffinityRepository;

    @Transactional(readOnly = true)
    public PoiFeedbackContext buildContext(UUID userId) {
        if (userId == null || !props.isEnabled()) {
            return PoiFeedbackContext.empty();
        }
        Map<String, Double> poi = new HashMap<>();
        for (UserPoiFeedback row : poiFeedbackRepository.findByUser_UserId(userId)) {
            poi.put(row.getPoiKey(), row.getScore());
        }
        Map<String, Double> cat = new HashMap<>();
        for (UserCategoryAffinity row : categoryAffinityRepository.findByUser_UserId(userId)) {
            cat.put(row.getCategoryKey(), row.getScore());
        }
        return new PoiFeedbackContext(Map.copyOf(poi), Map.copyOf(cat));
    }

    @Transactional
    public void record(User user, PoiFeedbackEventRequestDTO req) {
        if (user == null || req == null || !props.isEnabled()) {
            return;
        }
        PoiFeedbackEventType type = PoiFeedbackEventType.fromApi(req.eventType());
        if (type == null) {
            return;
        }
        double dPoi;
        double dCat;
        switch (type) {
            case THUMBS_UP -> {
                dPoi = props.getDeltaThumbsUpPoi();
                dCat = props.getDeltaThumbsUpCategory();
            }
            case THUMBS_DOWN -> {
                dPoi = props.getDeltaThumbsDownPoi();
                dCat = props.getDeltaThumbsDownCategory();
            }
            case REMOVE_POI -> {
                dPoi = props.getDeltaRemovePoi();
                dCat = props.getDeltaRemoveCategory();
            }
            default -> {
                return;
            }
        }

        String poiKey = resolvePoiStorageKey(req);
        if (poiKey != null) {
            upsertPoi(user, poiKey, dPoi);
        }
        if (req.categoryKeys() != null) {
            for (String raw : req.categoryKeys()) {
                String ck = PoiFeedbackKeyUtil.normalizeCategoryToken(raw);
                if (ck != null) {
                    upsertCategory(user, ck, dCat);
                }
            }
        }
    }

    private static String resolvePoiStorageKey(PoiFeedbackEventRequestDTO req) {
        String fs = PoiFeedbackKeyUtil.foursquareKey(req.foursquareId());
        if (fs != null) {
            return fs;
        }
        String mb = PoiFeedbackKeyUtil.mapboxKey(req.mapboxId());
        if (mb != null) {
            return mb;
        }
        return PoiFeedbackKeyUtil.waypointIdentityKey(req.waypointName(), req.latitude(), req.longitude());
    }

    private void upsertPoi(User user, String poiKey, double delta) {
        var existing = poiFeedbackRepository.findByUser_UserIdAndPoiKey(user.getUserId(), poiKey);
        double base = existing.map(UserPoiFeedback::getScore).orElse(0.0);
        double next = clamp(base + delta);
        if (Math.abs(next) <= NEUTRAL_SCORE_EPS) {
            existing.ifPresent(poiFeedbackRepository::delete);
            return;
        }
        UserPoiFeedback row = existing.orElseGet(() -> UserPoiFeedback.builder().user(user).poiKey(poiKey).build());
        row.setUser(user);
        row.setPoiKey(poiKey);
        row.setScore(next);
        poiFeedbackRepository.save(row);
    }

    private void upsertCategory(User user, String categoryKey, double delta) {
        var existing = categoryAffinityRepository.findByUser_UserIdAndCategoryKey(user.getUserId(), categoryKey);
        double base = existing.map(UserCategoryAffinity::getScore).orElse(0.0);
        double next = clamp(base + delta);
        if (Math.abs(next) <= NEUTRAL_SCORE_EPS) {
            existing.ifPresent(categoryAffinityRepository::delete);
            return;
        }
        UserCategoryAffinity row = existing.orElseGet(
                () -> UserCategoryAffinity.builder().user(user).categoryKey(categoryKey).build());
        row.setUser(user);
        row.setCategoryKey(categoryKey);
        row.setScore(next);
        categoryAffinityRepository.save(row);
    }

    private double clamp(double v) {
        double m = props.getMaxStoredAffinity();
        if (v > m) {
            return m;
        }
        if (v < -m) {
            return -m;
        }
        return v;
    }
}
