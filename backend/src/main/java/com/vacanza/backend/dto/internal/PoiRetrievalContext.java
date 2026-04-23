package com.vacanza.backend.dto.internal;

import java.time.LocalDate;

/**
 * Trip-relative inputs for POI retrieval constraints (closed days, future calendar rules).
 * When {@link #tripStart} or {@link #tripDayIndex} is missing, closed-day filtering is a no-op.
 *
 * @param tripStart    first calendar day of the trip (in the trip's local zone when wired)
 * @param tripDayIndex 1-based day within the trip (day 1 = {@code tripStart})
 * @param tripLengthDays optional total trip length for validation / future use
 */
public record PoiRetrievalContext(LocalDate tripStart, Integer tripDayIndex, Integer tripLengthDays) {

    public static PoiRetrievalContext empty() {
        return new PoiRetrievalContext(null, null, null);
    }
}
