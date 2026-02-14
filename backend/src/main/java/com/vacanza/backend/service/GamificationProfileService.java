package com.vacanza.backend.service;

import com.vacanza.backend.dto.response.GamificationProfileDTO;
import com.vacanza.backend.entity.*;
import com.vacanza.backend.repo.*;
import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Builds the gamification profile DTO for a given user.
 * All display texts are formed here — frontend receives ready-to-render data.
 */
@Service
@RequiredArgsConstructor

public class GamificationProfileService {

        private final UserGamificationProfileRepository profileRepo;
        private final LevelDefinitionRepository levelRepo;
        private final BadgeRepository badgeRepo;
        private final UserBadgeRepository userBadgeRepo;
        private final CheckInRepository checkInRepo;

        @Transactional(readOnly = true)
        public GamificationProfileDTO getProfile(User user) {
                // 1. XP
                int totalXp = profileRepo.findByUser(user)
                                .map(UserGamificationProfile::getTotalXp)
                                .orElse(0);

                // 2. Current level
                LevelDefinition currentLevel = levelRepo.findTopByMinXpLessThanEqualOrderByMinXpDesc(totalXp)
                                .orElse(LevelDefinition.builder().level(1).minXp(0).title("Newbie").build());

                // 3. Next level → progress calculation
                int xpProgressPercent;
                int xpToNextLevel;

                var nextLevelOpt = levelRepo.findTopByMinXpGreaterThanOrderByMinXpAsc(totalXp);
                if (nextLevelOpt.isPresent()) {
                        LevelDefinition nextLevel = nextLevelOpt.get();
                        int levelRange = nextLevel.getMinXp() - currentLevel.getMinXp();
                        int xpIntoLevel = totalXp - currentLevel.getMinXp();
                        xpProgressPercent = levelRange > 0 ? (int) ((xpIntoLevel * 100L) / levelRange) : 100;
                        xpToNextLevel = nextLevel.getMinXp() - totalXp;
                } else {
                        // Max level reached
                        xpProgressPercent = 100;
                        xpToNextLevel = 0;
                }

                // 4. Badges
                List<Badge> allBadges = badgeRepo.findAll();
                Set<Long> earnedBadgeIds = userBadgeRepo.findAllByUser(user).stream()
                                .map(ub -> ub.getBadge().getId())
                                .collect(Collectors.toSet());

                List<GamificationProfileDTO.BadgeDTO> badgeDTOs = allBadges.stream()
                                .map(b -> GamificationProfileDTO.BadgeDTO.builder()
                                                .id(b.getId())
                                                .title(b.getTitle())
                                                .key(b.getKey())
                                                .earned(earnedBadgeIds.contains(b.getId()))
                                                .build())
                                .toList();

                // 5. Stats
                long placesCount = checkInRepo.countByUser(user);
                long badgesCount = earnedBadgeIds.size();
                long daysCount = ChronoUnit.DAYS.between(user.getCreatedAt(), Instant.now());
                if (daysCount < 1)
                        daysCount = 1; // at least 1 day

                List<GamificationProfileDTO.StatDTO> stats = List.of(
                                GamificationProfileDTO.StatDTO.builder().label("Places").value(placesCount).build(),
                                GamificationProfileDTO.StatDTO.builder().label("Badges").value(badgesCount).build(),
                                GamificationProfileDTO.StatDTO.builder().label("Days").value(daysCount).build());

                // 6. Build response
                return GamificationProfileDTO.builder()
                                .roleText(currentLevel.getTitle())
                                .levelText("Level " + currentLevel.getLevel())
                                .xpProgressPercent(xpProgressPercent)
                                .xpToNextLevel(xpToNextLevel)
                                .totalXp(totalXp)
                                .badgesSectionTitle("Achievement Badges")
                                .stats(stats)
                                .badges(badgeDTOs)
                                .build();
        }
}
