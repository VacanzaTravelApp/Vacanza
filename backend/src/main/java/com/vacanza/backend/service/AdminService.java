package com.vacanza.backend.service;

import com.vacanza.backend.dto.response.AdminAnalyticsDTO;
import com.vacanza.backend.dto.response.SystemMonitoringDTO;

import java.time.LocalDate;

/**
 * Service interface for admin panel operations (UC2.1 + UC2.2).
 */
public interface AdminService {

    /**
     * UC2.1: Get system monitoring data (health, service statuses, API metrics, logs).
     */
    SystemMonitoringDTO getSystemMonitoring();

    /**
     * UC2.2: Get analytics report (users, check-ins, growth trends, category distribution, top POIs).
     */
    AdminAnalyticsDTO getAnalytics(LocalDate startDate, LocalDate endDate);
}
