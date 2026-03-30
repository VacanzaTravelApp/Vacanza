package com.vacanza.backend.entity.cache;

/**
 * Discriminator for the generic {@link ApiCache} table.
 */
public enum ApiCacheType {
    FLIGHT,
    HOTEL,
    AIRPORT
}
