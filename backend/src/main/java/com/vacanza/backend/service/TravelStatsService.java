package com.vacanza.backend.service;

import com.vacanza.backend.dto.response.TravelStatsDTO;
import com.vacanza.backend.entity.CheckIn;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.repo.CheckInRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Computes travel statistics for a given user from check-in data.
 */
@Service
@RequiredArgsConstructor
public class TravelStatsService {

    private final CheckInRepository checkInRepository;

    @Transactional(readOnly = true)
    public TravelStatsDTO getStats(User user) {
        long visitedCount = checkInRepository.countByUser(user);

        // Last visit
        CheckIn lastCheckIn = checkInRepository.findTopByUserOrderByCheckedInAtDesc(user)
                .orElse(null);

        // Favorite category
        String favoriteCategory = checkInRepository.findTopCategoryByUser(user)
                .orElse(null);

        // Distinct categories
        long distinctCategories = checkInRepository.countDistinctCategoriesByUser(user);

        return TravelStatsDTO.builder()
                .visitedPoisCount(visitedCount)
                .lastVisitDate(lastCheckIn != null ? lastCheckIn.getCheckedInAt() : null)
                .lastVisitPoiName(lastCheckIn != null ? lastCheckIn.getPointOfInterest().getName() : null)
                .favoriteCategory(favoriteCategory)
                .distinctCategoriesCount(distinctCategories)
                .build();
    }
}
