package com.vacanza.backend.service.impl;

import com.vacanza.backend.entity.*;
import com.vacanza.backend.event.CheckInCompletedEvent;
import com.vacanza.backend.repo.*;
import com.vacanza.backend.service.GamificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.List;

/**
 * Processes check-in events: awards XP and evaluates badge eligibility.
 * Called asynchronously after check-in transaction commits.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class GamificationServiceImpl implements GamificationService {

    public static final int XP_PER_CHECKIN = 50;

    private final UserGamificationProfileRepository profileRepo;
    private final BadgeRepository badgeRepo;
    private final UserBadgeRepository userBadgeRepo;
    private final CheckInRepository checkInRepo;
    private final UserRepository userRepo;

    @Override
    @Transactional
    public void processCheckIn(CheckInCompletedEvent event) {
        User user = userRepo.findById(event.getUserId())
                .orElseThrow(() -> new IllegalStateException(
                        "User not found: " + event.getUserId()));

        // 1. Award XP
        UserGamificationProfile profile = profileRepo.findByUser(user)
                .orElseGet(() -> UserGamificationProfile.builder()
                        .user(user)
                        .totalXp(0)
                        .build());

        profile.setTotalXp(profile.getTotalXp() + XP_PER_CHECKIN);
        profileRepo.save(profile);

        log.info("Awarded {}XP to userId={}, totalXp={}",
                XP_PER_CHECKIN, user.getUserId(), profile.getTotalXp());

        // 2. Check badge eligibility
        List<Badge> allBadges = badgeRepo.findAll();
        for (Badge badge : allBadges) {
            if (userBadgeRepo.existsByUserAndBadge(user, badge)) {
                continue; // already earned
            }

            if (isEligible(user, badge)) {
                UserBadge userBadge = UserBadge.builder()
                        .user(user)
                        .badge(badge)
                        .build();
                userBadgeRepo.save(userBadge);
                log.info("Badge earned! userId={}, badge='{}'", user.getUserId(), badge.getTitle());
            }
        }
    }

    private boolean isEligible(User user, Badge badge) {
        long count;
        switch (badge.getCriteriaType()) {
            case "TOTAL_COUNT":
                count = checkInRepo.countByUser(user);
                return count >= badge.getCriteriaThreshold();

            case "CATEGORY_COUNT":
                List<String> categories = Arrays.asList(badge.getCriteriaCategory().split(","));
                count = checkInRepo.countByUserAndCategories(user, categories);
                return count >= badge.getCriteriaThreshold();

            case "CATEGORY_DIVERSITY":
                count = checkInRepo.countDistinctCategoriesByUser(user);
                return count >= badge.getCriteriaThreshold();

            default:
                log.warn("Unknown criteria type: {}", badge.getCriteriaType());
                return false;
        }
    }
}
