package com.vacanza.backend.dto.internal;

import java.util.UUID;

/**
 * Tunings for {@link com.vacanza.backend.service.PersonalizedPoiSelector}.
 *
 * @param retrievalContext trip-relative constraints (closed days, etc.)
 * @param maxForLlm        hard cap on POIs passed to the LLM; when null, uses {@code vacanza.poi-diversity.target-count}
 * @param userId           when non-null, {@link com.vacanza.backend.service.UserFeedbackService} affinities apply to scoring
 */
public record PersonalizedPoiParams(PoiRetrievalContext retrievalContext, Integer maxForLlm, UUID userId) {

    public static PersonalizedPoiParams defaults() {
        return new PersonalizedPoiParams(PoiRetrievalContext.empty(), null, null);
    }

    public static PersonalizedPoiParams forUser(UUID userId) {
        return new PersonalizedPoiParams(PoiRetrievalContext.empty(), null, userId);
    }
}
