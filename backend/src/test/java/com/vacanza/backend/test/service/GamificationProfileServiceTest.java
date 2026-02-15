package com.vacanza.backend.test.service;

import com.vacanza.backend.dto.response.GamificationProfileDTO;
import com.vacanza.backend.entity.*;
import com.vacanza.backend.repo.*;
import com.vacanza.backend.service.GamificationProfileService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GamificationProfileServiceTest {

        @Mock
        private UserGamificationProfileRepository profileRepo;
        @Mock
        private LevelDefinitionRepository levelRepo;
        @Mock
        private BadgeRepository badgeRepo;
        @Mock
        private UserBadgeRepository userBadgeRepo;
        @Mock
        private CheckInRepository checkInRepo;

        @InjectMocks
        private GamificationProfileService service;

        private User testUser;

        @BeforeEach
        void setUp() {
                testUser = new User();
                testUser.setUserId(UUID.randomUUID());
                testUser.setFirebaseUid("test-uid");
                testUser.setEmail("test@test.com");
                testUser.setCreatedAt(Instant.now().minus(30, ChronoUnit.DAYS));
        }

    @Test
    @DisplayName("Should resolve correct level and progress for mid-range XP")
    void shouldResolveLevelAndProgress() {
        when(profileRepo.findByUser(testUser))
                .thenReturn(Optional.of(UserGamificationProfile.builder()
                        .totalXp(350).user(testUser).build()));
        when(levelRepo.findTopByMinXpLessThanEqualOrderByMinXpDesc(350))
                .thenReturn(Optional.of(LevelDefinition.builder()
                        .level(3).minXp(300).title("Traveler").build()));
        when(levelRepo.findTopByMinXpGreaterThanOrderByMinXpAsc(350))
                .thenReturn(Optional.of(LevelDefinition.builder()
                        .level(4).minXp(600).title("Adventurer").build()));
        when(badgeRepo.findAll()).thenReturn(List.of());
        when(userBadgeRepo.findAllByUser(testUser)).thenReturn(List.of());
        when(checkInRepo.countByUser(testUser)).thenReturn(7L);

        GamificationProfileDTO dto = service.getProfile(testUser);

        assertThat(dto.getRoleText()).isEqualTo("Traveler");
        assertThat(dto.getLevelText()).isEqualTo("Level 3");
        assertThat(dto.getTotalXp()).isEqualTo(350);
        assertThat(dto.getXpProgressPercent()).isEqualTo(16);
        assertThat(dto.getXpToNextLevel()).isEqualTo(250);
    }

    @Test
    @DisplayName("Should show 100% progress at max level")
    void shouldShowMaxLevelProgress() {
        when(profileRepo.findByUser(testUser))
                .thenReturn(Optional.of(UserGamificationProfile.builder()
                        .totalXp(6000).user(testUser).build()));
        when(levelRepo.findTopByMinXpLessThanEqualOrderByMinXpDesc(6000))
                .thenReturn(Optional.of(LevelDefinition.builder()
                        .level(10).minXp(5500).title("Grandmaster").build()));
        when(levelRepo.findTopByMinXpGreaterThanOrderByMinXpAsc(6000))
                .thenReturn(Optional.empty());
        when(badgeRepo.findAll()).thenReturn(List.of());
        when(userBadgeRepo.findAllByUser(testUser)).thenReturn(List.of());
        when(checkInRepo.countByUser(testUser)).thenReturn(120L);

        GamificationProfileDTO dto = service.getProfile(testUser);

        assertThat(dto.getRoleText()).isEqualTo("Grandmaster");
        assertThat(dto.getXpProgressPercent()).isEqualTo(100);
        assertThat(dto.getXpToNextLevel()).isEqualTo(0);
    }

    @Test
    @DisplayName("Should return default profile for new user with 0 XP")
    void shouldReturnDefaultForNewUser() {
        when(profileRepo.findByUser(testUser)).thenReturn(Optional.empty());
        when(levelRepo.findTopByMinXpLessThanEqualOrderByMinXpDesc(0))
                .thenReturn(Optional.of(LevelDefinition.builder()
                        .level(1).minXp(0).title("Newbie").build()));
        when(levelRepo.findTopByMinXpGreaterThanOrderByMinXpAsc(0))
                .thenReturn(Optional.of(LevelDefinition.builder()
                        .level(2).minXp(100).title("Explorer").build()));
        when(badgeRepo.findAll()).thenReturn(List.of());
        when(userBadgeRepo.findAllByUser(testUser)).thenReturn(List.of());
        when(checkInRepo.countByUser(testUser)).thenReturn(0L);

        GamificationProfileDTO dto = service.getProfile(testUser);

        assertThat(dto.getRoleText()).isEqualTo("Newbie");
        assertThat(dto.getLevelText()).isEqualTo("Level 1");
        assertThat(dto.getTotalXp()).isEqualTo(0);
        assertThat(dto.getXpProgressPercent()).isEqualTo(0);
        assertThat(dto.getXpToNextLevel()).isEqualTo(100);
    }

        @Test
        @DisplayName("Should correctly map earned and unearned badges")
        void shouldMapBadgesCorrectly() {
                Badge badge1 = Badge.builder().id(1L).key("speed").title("First Step")
                                .criteriaType("TOTAL_COUNT").criteriaThreshold(1).build();
                Badge badge2 = Badge.builder().id(2L).key("foodie").title("Foodie")
                                .criteriaType("CATEGORY_COUNT").criteriaCategory("restaurant,cafe").criteriaThreshold(3)
                                .build();

                UserBadge earnedBadge = UserBadge.builder().badge(badge1).user(testUser).build();

                when(profileRepo.findByUser(testUser)).thenReturn(Optional.empty());
                when(levelRepo.findTopByMinXpLessThanEqualOrderByMinXpDesc(0))
                                .thenReturn(Optional.of(
                                                LevelDefinition.builder().level(1).minXp(0).title("Newbie").build()));
                when(levelRepo.findTopByMinXpGreaterThanOrderByMinXpAsc(0))
                                .thenReturn(Optional.of(LevelDefinition.builder().level(2).minXp(100).title("Explorer")
                                                .build()));
                when(badgeRepo.findAll()).thenReturn(List.of(badge1, badge2));
                when(userBadgeRepo.findAllByUser(testUser)).thenReturn(List.of(earnedBadge));
                when(checkInRepo.countByUser(testUser)).thenReturn(1L);

                GamificationProfileDTO dto = service.getProfile(testUser);

                assertThat(dto.getBadges()).hasSize(2);
                assertThat(dto.getBadges().get(0).isEarned()).isTrue();
                assertThat(dto.getBadges().get(0).getKey()).isEqualTo("speed");
                assertThat(dto.getBadges().get(1).isEarned()).isFalse();
                assertThat(dto.getBadges().get(1).getKey()).isEqualTo("foodie");
        }

    @Test
    @DisplayName("Should include correct stats: Places, Badges, Days")
    void shouldIncludeCorrectStats() {
        when(profileRepo.findByUser(testUser)).thenReturn(Optional.empty());
        when(levelRepo.findTopByMinXpLessThanEqualOrderByMinXpDesc(0))
                .thenReturn(Optional.of(LevelDefinition.builder().level(1).minXp(0).title("Newbie").build()));
        when(levelRepo.findTopByMinXpGreaterThanOrderByMinXpAsc(0))
                .thenReturn(Optional.of(LevelDefinition.builder().level(2).minXp(100).title("Explorer").build()));
        when(badgeRepo.findAll()).thenReturn(List.of());
        when(userBadgeRepo.findAllByUser(testUser)).thenReturn(List.of());
        when(checkInRepo.countByUser(testUser)).thenReturn(24L);

        GamificationProfileDTO dto = service.getProfile(testUser);

        assertThat(dto.getStats()).hasSize(3);
        assertThat(dto.getStats().get(0).getLabel()).isEqualTo("Places");
        assertThat(dto.getStats().get(0).getValue()).isEqualTo(24L);
        assertThat(dto.getStats().get(1).getLabel()).isEqualTo("Badges");
        assertThat(dto.getStats().get(2).getLabel()).isEqualTo("Days");
        assertThat(dto.getStats().get(2).getValue()).isGreaterThanOrEqualTo(30L);
        assertThat(dto.getBadgesSectionTitle()).isEqualTo("Achievement Badges");
    }
}
