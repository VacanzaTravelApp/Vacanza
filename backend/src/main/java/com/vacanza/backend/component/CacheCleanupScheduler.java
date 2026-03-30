package com.vacanza.backend.component;

import com.vacanza.backend.repo.ApiCacheRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Slf4j
@Component
@RequiredArgsConstructor
public class CacheCleanupScheduler {

    private final ApiCacheRepository cacheRepo;

    @Transactional
    @Scheduled(cron = "0 0 3 * * *")
    public void purgeExpiredEntries() {
        Instant now = Instant.now();
        long before = cacheRepo.count();
        cacheRepo.deleteAllByExpiresAtBefore(now);
        long after = cacheRepo.count();
        log.info("[CACHE CLEANUP] Purged {} expired entries, {} remaining",
                before - after, after);
    }
}
