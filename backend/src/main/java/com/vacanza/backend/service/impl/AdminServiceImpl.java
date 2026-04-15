package com.vacanza.backend.service.impl;

import com.vacanza.backend.component.ApiMetricsCollector;
import com.vacanza.backend.component.SystemLogCollector;
import com.vacanza.backend.dto.response.AdminAnalyticsDTO;
import com.vacanza.backend.dto.response.AdminAnalyticsDTO.*;
import com.vacanza.backend.dto.response.SystemMonitoringDTO;
import com.vacanza.backend.dto.response.SystemMonitoringDTO.*;
import com.vacanza.backend.repo.CheckInRepository;
import com.vacanza.backend.repo.PointOfInterestRepository;
import com.vacanza.backend.repo.UserLoginHistoryRepository;
import com.vacanza.backend.repo.UserRepository;
import com.vacanza.backend.service.AdminService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.actuate.health.HealthEndpoint;
import org.springframework.boot.actuate.health.Status;
import org.springframework.stereotype.Service;


import java.lang.management.ManagementFactory;
import java.time.Instant;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Admin service implementation aggregating data from repositories,
 * API metrics collector, and Spring Actuator health endpoint.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AdminServiceImpl implements AdminService {

    private final UserRepository userRepository;
    private final CheckInRepository checkInRepository;
    private final UserLoginHistoryRepository loginHistoryRepository;
    private final PointOfInterestRepository poiRepository;
    private final ApiMetricsCollector apiMetricsCollector;
    private final SystemLogCollector systemLogCollector;
    private final HealthEndpoint healthEndpoint;

    // ── UC2.1: System Monitoring ────────────────────────────────

    @Override
    public SystemMonitoringDTO getSystemMonitoring() {
        log.info("Fetching system monitoring data");

        // API usage metrics
        List<ApiUsageMetric> apiMetrics = apiMetricsCollector.getMetrics();

        // Service statuses derived from Actuator health and live API performance
        List<ServiceStatus> services = buildServiceStatuses(apiMetrics);

        // Calculate overall health score based on derived microservice statuses
        long upCount = services.stream()
                .filter(s -> "UP".equals(s.getStatus()))
                .count();
        double systemHealth = services.isEmpty() ? 0.0
                : Math.round(((double) upCount / services.size()) * 100.0) / 100.0;

        // System uptime from JVM runtime
        long uptimeMs = ManagementFactory.getRuntimeMXBean().getUptime();
        long uptimeSeconds = uptimeMs / 1000;
        Instant startTime = Instant.now().minusMillis(uptimeMs);

        // Recent logs from login history
        List<LogEntry> logs = buildRecentLogs();

        return SystemMonitoringDTO.builder()
                .systemHealth(systemHealth)
                .uptimeSeconds(uptimeSeconds)
                .serverStartTime(startTime.toString())
                .services(services)
                .apiMetrics(apiMetrics)
                .logs(logs)
                .build();
    }

    private List<ServiceStatus> buildServiceStatuses(List<ApiUsageMetric> apiMetrics) {
        List<ServiceStatus> services = new ArrayList<>();

        // Baseline: The Spring Boot application must be up.
        boolean systemUp = healthEndpoint.health().getStatus().equals(Status.UP);

        // Core Internal Services
        services.add(ServiceStatus.builder()
                .name("Auth Service").status(determineComponentHealth(systemUp, apiMetrics, "Internal: /auth")).build());
        services.add(ServiceStatus.builder()
                .name("User Service").status(determineComponentHealth(systemUp, apiMetrics, "Internal: /user")).build());
        services.add(ServiceStatus.builder()
                .name("Gamification Engine").status(determineComponentHealth(systemUp, apiMetrics, "Internal: /gamification")).build());

        // External Data Providers (Third-Party)
        services.add(ServiceStatus.builder()
                .name("Maps & Geocoding (Mapbox)").status(determineComponentHealth(systemUp, apiMetrics, "Mapbox")).build());
        services.add(ServiceStatus.builder()
                .name("Local Places (Foursquare)").status(determineComponentHealth(systemUp, apiMetrics, "Foursquare")).build());
        services.add(ServiceStatus.builder()
                .name("Hotel Search (SerpApi)").status(determineComponentHealth(systemUp, apiMetrics, "SerpApi")).build());
        services.add(ServiceStatus.builder()
                .name("Events (Ticketmaster)").status(determineComponentHealth(systemUp, apiMetrics, "Ticketmaster")).build());
        services.add(ServiceStatus.builder()
                .name("Tours/Activities (Viator)").status(determineComponentHealth(systemUp, apiMetrics, "Viator")).build());
        services.add(ServiceStatus.builder()
                .name("Currency Exchange (Frankfurter)").status(determineComponentHealth(systemUp, apiMetrics, "Frankfurter")).build());
        services.add(ServiceStatus.builder()
                .name("Weather Service (OpenMeteo)").status(determineComponentHealth(systemUp, apiMetrics, "OpenMeteo")).build());

        // Advanced Logic Components
        services.add(ServiceStatus.builder()
                .name("AI Recommendation Engine").status(determineComponentHealth(systemUp, apiMetrics, "AI")).build());

        // Internal Endpoint Health
        services.add(ServiceStatus.builder()
                .name("Internal: Booking Controllers").status(determineComponentHealth(systemUp, apiMetrics, "Internal: /booking")).build());
        services.add(ServiceStatus.builder()
                .name("Internal: POI Controllers").status(determineComponentHealth(systemUp, apiMetrics, "Internal: /poi")).build());

        return services;
    }

    private String determineComponentHealth(boolean systemUp, List<ApiUsageMetric> metrics, String... relatedApiNames) {
        if (!systemUp) return "DOWN";
        
        for (ApiUsageMetric m : metrics) {
            for (String key : relatedApiNames) {
                if (m.getApiName() != null && m.getApiName().toLowerCase().contains(key.toLowerCase())) {
                    // Circuit Breaker logic: If an API fails 3 times in a row, the component is down.
                    // The moment it successfully responds once, it immediately returns to UP.
                    if (m.getConsecutiveErrors() >= 3) {
                        return "DOWN";
                    }
                }
            }
        }
        
        return "UP";
    }

    private List<LogEntry> buildRecentLogs() {
        List<LogEntry> loginLogs = loginHistoryRepository.findTop50ByOrderByLoginTimeDesc().stream()
                .map(lh -> LogEntry.builder()
                        .timestamp(lh.getLoginTime().toString())
                        .level("SUCCESS")
                        .message("User login via " + lh.getLoginProvider()
                                + (lh.getIpAddress() != null ? " from " + lh.getIpAddress() : ""))
                        .source("AUTH")
                        .build())
                .collect(Collectors.toList());

        List<LogEntry> systemLogs = systemLogCollector.getRecentLogs();

        List<LogEntry> allLogs = new ArrayList<>();
        allLogs.addAll(loginLogs);
        allLogs.addAll(systemLogs);

        allLogs.sort((l1, l2) -> {
            try {
                Instant t1 = Instant.parse(l1.getTimestamp());
                Instant t2 = Instant.parse(l2.getTimestamp());
                return t2.compareTo(t1);
            } catch (Exception e) {
                return 0;
            }
        });

        return allLogs.stream().limit(50).collect(Collectors.toList());
    }

    // ── UC2.2: Analytics Report ─────────────────────────────────

    @Override
    public AdminAnalyticsDTO getAnalytics(LocalDate startDate, LocalDate endDate) {
        log.info("Fetching analytics report: startDate={}, endDate={}", startDate, endDate);

        // Matrix Users: Total users in range (or total users as a baseline)
        long matrixUsers = userRepository.count();

        // Global Revenue: Placeholder for actual booking financial volume
        // Since we don't have a 'confirmed_bookings' table yet, we return 0.0 or a safe mock.
        double globalRevenue = 0.0;

        // Active Nodes: Total POIs in the database
        long activeNodes = poiRepository.count();

        // Avg. Duration: Mocking average session duration (e.g. 1.5 hours)
        double avgDuration = 1.5;

        // Growth Trajectory (last 6 months)
        List<GrowthMetric> growthTrajectory = buildGrowthTrends();

        // Category Breakdown
        List<CategoryMetric> categoryBreakdown = checkInRepository.findCategoryDistribution().stream()
                .map(row -> CategoryMetric.builder()
                        .name((String) row[0])
                        .value((Long) row[1])
                        .build())
                .collect(Collectors.toList());

        // High Performance Asset Ranking (Top POIs)
        // Normalize visit counts to a 0-10 score scale
        List<Object[]> topPoiRows = checkInRepository.findTopPois().stream()
                .limit(10)
                .collect(Collectors.toList());

        long maxVisits = topPoiRows.stream()
                .mapToLong(row -> (Long) row[2])
                .max()
                .orElse(1L);

        List<HighPerformanceAssetMetric> highPerformanceAssets = topPoiRows.stream()
                .map(row -> {
                    long visits = (Long) row[2];
                    double score = Math.round(((double) visits / maxVisits) * 100.0) / 10.0;
                    return HighPerformanceAssetMetric.builder()
                            .name((String) row[0])
                            .category((String) row[1])
                            .score(score)
                            .build();
                })
                .collect(Collectors.toList());

        // Active sessions: users who logged in within the last 30 minutes
        long activeSessions = loginHistoryRepository.countByLoginTimeAfter(
                Instant.now().minus(30, ChronoUnit.MINUTES));

        return AdminAnalyticsDTO.builder()
                .matrixUsers(matrixUsers)
                .globalRevenue(globalRevenue)
                .activeNodes(activeNodes)
                .avgDuration(avgDuration)
                .activeSessions(activeSessions)
                .growthTrajectory(growthTrajectory)
                .categoryBreakdown(categoryBreakdown)
                .highPerformanceAssets(highPerformanceAssets)
                .build();
    }

    private List<GrowthMetric> buildGrowthTrends() {
        List<GrowthMetric> trends = new ArrayList<>();
        YearMonth current = YearMonth.now();

        // Last 6 months
        for (int i = 5; i >= 0; i--) {
            YearMonth month = current.minusMonths(i);
            Instant monthStart = month.atDay(1).atStartOfDay().toInstant(ZoneOffset.UTC);
            Instant monthEnd = month.atEndOfMonth().atStartOfDay().toInstant(ZoneOffset.UTC);

            // Count users created after monthStart and before monthEnd
            long totalAfterStart = userRepository.countByCreatedAtAfter(monthStart);
            long totalAfterEnd = userRepository.countByCreatedAtAfter(monthEnd);
            long newUsers = totalAfterStart - totalAfterEnd;

            trends.add(GrowthMetric.builder()
                    .period(month.toString())  // e.g. "2026-03"
                    .newUsers(Math.max(0, newUsers))
                    .build());
        }
        return trends;
    }
}
