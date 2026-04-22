package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Response DTO for POST /admin/health-check/{serviceName}.
 * Returns the result of an on-demand health check for a specific external API.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HealthCheckResultDTO {

    /** Display name of the service (e.g. "Frankfurter API") */
    private String serviceName;

    /** "UP" or "DOWN" */
    private String status;

    /** Round-trip response time in milliseconds */
    private long responseMs;

    /** "OK" on success, or error description on failure */
    private String message;

    /** ISO-8601 timestamp of when this check was performed */
    private String checkedAt;
}
