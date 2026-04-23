package com.vacanza.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Error body for polygon route generation failures (4xx).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PolygonRouteErrorResponse {
    /** Stable machine-readable code, e.g. INVALID_POLYGON, POLYGON_TOO_LARGE */
    private String code;
    private String message;
}
