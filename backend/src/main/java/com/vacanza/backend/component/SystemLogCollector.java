package com.vacanza.backend.component;

import com.vacanza.backend.dto.response.SystemMonitoringDTO.LogEntry;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.concurrent.ConcurrentLinkedDeque;

/**
 * In-memory collector for system logs/exceptions.
 * Stores the most recent errors to display on the admin monitoring dashboard.
 */
@Component
public class SystemLogCollector {

    private static final int MAX_LOGS = 100;
    private final ConcurrentLinkedDeque<LogEntry> logs = new ConcurrentLinkedDeque<>();

    /**
     * Resets the system log history bi-weekly (1st and 15th).
     */
    @Scheduled(cron = "0 0 0 1,15 * *")
    public void resetLogs() {
        logs.clear();
    }

    public void recordError(String path, String message) {
        LogEntry entry = LogEntry.builder()
                .timestamp(Instant.now().toString())
                .level("ERROR")
                .message(message)
                .source(path != null && !path.isBlank() ? path : "SYSTEM")
                .build();

        logs.addFirst(entry);
        
        // Keep size bounded to avoid memory leaks
        while (logs.size() > MAX_LOGS) {
            logs.pollLast();
        }
    }

    public List<LogEntry> getRecentLogs() {
        return logs.stream().toList();
    }
}
