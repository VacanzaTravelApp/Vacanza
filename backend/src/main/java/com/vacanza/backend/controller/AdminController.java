package com.vacanza.backend.controller;

import com.vacanza.backend.dto.response.AdminAnalyticsDTO;
import com.vacanza.backend.dto.response.HealthCheckResultDTO;
import com.vacanza.backend.dto.response.SystemMonitoringDTO;
import com.vacanza.backend.service.AdminService;
import com.vacanza.backend.service.ApiHealthCheckService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Map;

/**
 * REST controller for admin panel operations.
 * All endpoints under /admin are restricted to ADMIN role.
 */
@Slf4j
@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final ApiHealthCheckService apiHealthCheckService;

    /**
     * UC2.1: Get system monitoring data.
     * Returns system health, service statuses, API usage metrics, and recent logs.
     */
    @GetMapping("/monitoring")
    public ResponseEntity<SystemMonitoringDTO> getSystemMonitoring() {
        log.info("Admin monitoring request");
        return ResponseEntity.ok(adminService.getSystemMonitoring());
    }

    /**
     * UC2.2: Get analytics report.
     * Returns user growth, check-in stats, category distribution, and top POIs.
     *
     * @param startDate optional start date filter (YYYY-MM-DD)
     * @param endDate   optional end date filter (YYYY-MM-DD)
     */
    @GetMapping("/analytics")
    public ResponseEntity<AdminAnalyticsDTO> getAnalytics(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {

        log.info("Admin analytics request: startDate={}, endDate={}", startDate, endDate);
        return ResponseEntity.ok(adminService.getAnalytics(startDate, endDate));
    }

    /**
     * On-demand health check for a specific external API.
     * Sends a lightweight ping request to the target service and returns the result.
     *
     * Supported services: foursquare, mapbox, serpapi, ticketmaster,
     *                     openmeteo, frankfurter, viator, ai
     *
     * @param serviceName the service identifier (case-insensitive)
     * @return health check result with status (UP/DOWN), response time, and message
     */
    @PostMapping("/health-check/{serviceName}")
    public ResponseEntity<?> performHealthCheck(@PathVariable String serviceName) {
        log.info("Admin health-check request: service={}", serviceName);
        try {
            HealthCheckResultDTO result = apiHealthCheckService.check(serviceName);
            return ResponseEntity.ok(result);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Bad Request",
                    "message", e.getMessage(),
                    "supportedServices", apiHealthCheckService.getSupportedServices()
            ));
        }
    }
}

