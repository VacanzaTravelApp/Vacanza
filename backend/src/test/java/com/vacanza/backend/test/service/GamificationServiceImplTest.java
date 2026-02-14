package com.vacanza.backend.test.service;

import com.vacanza.backend.entity.*;
import com.vacanza.backend.entity.enums.CheckInSource;
import com.vacanza.backend.event.CheckInCompletedEvent;
import com.vacanza.backend.repo.*;
import com.vacanza.backend.service.impl.GamificationServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GamificationServiceImplTest {

    @Mock
    private UserGamificationProfileRepository profileRepo;
    @Mock
    private BadgeRepository badgeRepo;
    @Mock
    private UserBadgeRepository userBadgeRepo;
    @Mock
    private CheckInRepository checkInRepo;
    @Mock
    private UserRepository userRepo;

    @InjectMocks
    private GamificationServiceImpl service;

    private User testUser;
    private CheckInCompletedEvent sampleEvent;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setUserId(UUID.randomUUID());
        testUser.setFirebaseUid("test-uid");
        testUser.setEmail("test@test.com");

        sampleEvent = CheckInCompletedEvent.builder()
                .checkInId(UUID.randomUUID())
                .userId(testUser.getUserId())
                .poiId(UUID.randomUUID())
                .poiName("Test POI")
                .checkedInAt(Instant.now())
                .source(CheckInSource.AUTO)
                .build();
    }

    @Test
    @DisplayName("Should award XP on check-in for existing profile")
    void shouldAwardXp_ExistingProfile() {
        UserGamificationProfile profile = UserGamificationProfile.builder()
                .user(testUser).totalXp(100).build();

        when(userRepo.findById(testUser.getUserId())).thenReturn(Optional.of(testUser));
        when(profileRepo.findByUser(testUser)).thenReturn(Optional.of(profile));
        when(badgeRepo.findAll()).thenReturn(List.of());
        when(profileRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service.processCheckIn(sampleEvent);

        verify(profileRepo).save(argThat(p -> p.getTotalXp() == 150));
    }

    @Test
    @DisplayName("Should create new profile with XP for first-time user")
    void shouldCreateProfile_FirstCheckIn() {
        when(userRepo.findById(testUser.getUserId())).thenReturn(Optional.of(testUser));
        when(profileRepo.findByUser(testUser)).thenReturn(Optional.empty());
        when(badgeRepo.findAll()).thenReturn(List.of());
        when(profileRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service.processCheckIn(sampleEvent);

        verify(profileRepo).save(argThat(p ->
                p.getTotalXp() == GamificationServiceImpl.XP_PER_CHECKIN &&
                p.getUser().equals(testUser)));
    }

    @Test
    @DisplayName("Should earn TOTAL_COUNT badge when threshold reached")
    void shouldEarnBadge_TotalCount() {
        Badge speedBadge = Badge.builder()
                .id(1L).key("speed").title("First Step")
                .criteriaType("TOTAL_COUNT").criteriaThreshold(1).build();

        when(userRepo.findById(testUser.getUserId())).thenReturn(Optional.of(testUser));
        when(profileRepo.findByUser(testUser)).thenReturn(Optional.empty());
        when(profileRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(badgeRepo.findAll()).thenReturn(List.of(speedBadge));
        when(userBadgeRepo.existsByUserAndBadge(testUser, speedBadge)).thenReturn(false);
        when(checkInRepo.countByUser(testUser)).thenReturn(1L);

        service.processCheckIn(sampleEvent);

        verify(userBadgeRepo).save(argThat(ub -> ub.getBadge().equals(speedBadge) && ub.getUser().equals(testUser)));
    }

    @Test
    @DisplayName("Should NOT duplicate badge if already earned")
    void shouldNotDuplicateBadge() {
        Badge speedBadge = Badge.builder()
                .id(1L).key("speed").title("First Step")
                .criteriaType("TOTAL_COUNT").criteriaThreshold(1).build();

        when(userRepo.findById(testUser.getUserId())).thenReturn(Optional.of(testUser));
        when(profileRepo.findByUser(testUser)).thenReturn(Optional.empty());
        when(profileRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(badgeRepo.findAll()).thenReturn(List.of(speedBadge));
        when(userBadgeRepo.existsByUserAndBadge(testUser, speedBadge)).thenReturn(true);

        service.processCheckIn(sampleEvent);

        verify(userBadgeRepo, never()).save(any());
    }

    @Test
    @DisplayName("Should earn CATEGORY_COUNT badge when category threshold reached")
    void shouldEarnBadge_CategoryCount() {
        Badge foodieBadge = Badge.builder()
                .id(2L).key("foodie").title("Foodie")
                .criteriaType("CATEGORY_COUNT")
                .criteriaCategory("restaurant,cafe")
                .criteriaThreshold(3).build();

        when(userRepo.findById(testUser.getUserId())).thenReturn(Optional.of(testUser));
        when(profileRepo.findByUser(testUser)).thenReturn(Optional.empty());
        when(profileRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(badgeRepo.findAll()).thenReturn(List.of(foodieBadge));
        when(userBadgeRepo.existsByUserAndBadge(testUser, foodieBadge)).thenReturn(false);
        when(checkInRepo.countByUserAndCategories(testUser, List.of("restaurant", "cafe"))).thenReturn(3L);

        service.processCheckIn(sampleEvent);

        verify(userBadgeRepo).save(argThat(ub -> ub.getBadge().getKey().equals("foodie")));
    }
}
