package com.vacanza.backend.component;

import com.vacanza.backend.dto.response.SystemMonitoringDTO.ApiUsageMetric;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.LongAdder;

/**
 * In-memory collector for API call metrics.
 * Each API client should call recordCall() on success and recordError() on failure.
 * Provides current-day metrics for the admin monitoring dashboard.
 */
@Component
public class ApiMetricsCollector {

    private final Map<String, ApiCounter> counters = new ConcurrentHashMap<>();

    /**
     * Record a successful API call with its response time.
     */
    public void recordCall(String apiName, long responseTimeMs) {
        getOrCreate(apiName).recordCall(responseTimeMs);
    }

    /**
     * Record a failed API call (4xx/5xx).
     */
    public void recordError(String apiName) {
        getOrCreate(apiName).recordError();
    }

    /**
     * Get current metrics for all tracked APIs.
     */
    public List<ApiUsageMetric> getMetrics() {
        return counters.entrySet().stream()
                .map(entry -> {
                    ApiCounter c = entry.getValue();
                    long total = c.totalCalls.sum();
                    double avgMs = total > 0
                            ? (double) c.totalResponseTimeMs.sum() / total
                            : 0.0;
                    return ApiUsageMetric.builder()
                            .apiName(entry.getKey())
                            .totalCalls(total)
                            .errorCount(c.errorCount.sum())
                            .avgResponseMs(Math.round(avgMs * 100.0) / 100.0)
                            .build();
                })
                .toList();
    }

    private ApiCounter getOrCreate(String apiName) {
        return counters.computeIfAbsent(apiName, k -> new ApiCounter());
    }

    /**
     * Per-API counter using thread-safe LongAdder for high concurrency.
     */
    private static class ApiCounter {
        final LongAdder totalCalls = new LongAdder();
        final LongAdder errorCount = new LongAdder();
        final LongAdder totalResponseTimeMs = new LongAdder();

        void recordCall(long responseTimeMs) {
            totalCalls.increment();
            totalResponseTimeMs.add(responseTimeMs);
        }

        void recordError() {
            errorCount.increment();
        }
    }
}
