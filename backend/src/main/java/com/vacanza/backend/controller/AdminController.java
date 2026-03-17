package com.vacanza.backend.controller;

import com.vacanza.backend.dto.response.AdminAnalyticsDTO;
import com.vacanza.backend.dto.response.SystemMonitoringDTO;
import com.vacanza.backend.service.AdminService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

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
}
