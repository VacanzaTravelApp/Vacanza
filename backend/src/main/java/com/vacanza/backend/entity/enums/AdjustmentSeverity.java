package com.vacanza.backend.entity.enums;

/**
 * How urgently the adjustment should be applied.
 *
 * <ul>
 *   <li>{@code LOW}      – minor inconvenience; waypoint marked unavailable but kept in plan.</li>
 *   <li>{@code MEDIUM}   – attempt to find a same-category replacement.</li>
 *   <li>{@code HIGH}     – must replace or remove the waypoint.</li>
 *   <li>{@code CRITICAL} – whole day may be unusable (e.g. hurricane); full-day rescheduling.</li>
 * </ul>
 */
public enum AdjustmentSeverity {
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL
}
