package com.vacanza.backend.dto.internal;

/**
 * Tunings for {@link com.vacanza.backend.service.PersonalizedPoiSelector}.
 *
 * @param retrievalContext trip-relative constraints (closed days, etc.)
 * @param maxForLlm        hard cap on POIs passed to the LLM; when null, uses {@code vacanza.poi-diversity.target-count}
 */
public record PersonalizedPoiParams(PoiRetrievalContext retrievalContext, Integer maxForLlm) {

    public static PersonalizedPoiParams defaults() {
        return new PersonalizedPoiParams(PoiRetrievalContext.empty(), null);
    }
}
