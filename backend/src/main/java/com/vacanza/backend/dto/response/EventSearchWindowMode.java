package com.vacanza.backend.dto.response;

/**
 * How Ticketmaster date range was chosen for event recommendations (for UI copy / progressive disclosure).
 */
public enum EventSearchWindowMode {
    /** ~30 days from today — user did not lock {@code trip_dates_user_specified}. */
    BROAD_30_DAYS,
    /** Trip window from route/weather — user locked calendar dates. */
    TRIP_DATES
}
