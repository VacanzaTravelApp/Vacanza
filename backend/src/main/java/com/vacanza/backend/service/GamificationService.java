package com.vacanza.backend.service;

import com.vacanza.backend.event.CheckInCompletedEvent;

/**
 * Processes check-in events for gamification: awards XP and evaluates badge
 * eligibility.
 */
public interface GamificationService {
    void processCheckIn(CheckInCompletedEvent event);
}
