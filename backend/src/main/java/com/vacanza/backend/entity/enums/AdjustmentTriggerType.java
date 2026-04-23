package com.vacanza.backend.entity.enums;

/**
 * Reason an itinerary adjustment was triggered.
 *
 * <ul>
 *   <li>{@code WEATHER_ALERT} – scheduler detected severe weather for the trip dates.</li>
 *   <li>{@code POI_CLOSURE}   – an external data source or operator reported a POI closed.</li>
 *   <li>{@code USER_REPORTED} – the traveller tapped "this place is closed/unavailable".</li>
 *   <li>{@code CROWDING_HIGH} – optional: real-time crowd signal (future extension).</li>
 * </ul>
 */
public enum AdjustmentTriggerType {
    WEATHER_ALERT,
    POI_CLOSURE,
    USER_REPORTED,
    CROWDING_HIGH
}
