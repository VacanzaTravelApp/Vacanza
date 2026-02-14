package com.vacanza.backend.service;

import com.vacanza.backend.dto.AutoCheckInRequestDTO;
import com.vacanza.backend.dto.CheckInResponseDTO;
import com.vacanza.backend.entity.CheckIn;
import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.enums.CheckInSource;
import com.vacanza.backend.repo.CheckInRepository;
import com.vacanza.backend.repo.PointOfInterestRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CheckInServiceTest {

    @Mock
    private CheckInRepository checkInRepository;

    @Mock
    private PointOfInterestRepository poiRepository;

    @InjectMocks
    private CheckInService checkInService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setUserId(UUID.randomUUID());
        testUser.setFirebaseUid("test-uid");
        testUser.setEmail("test@test.com");
    }

    // ──────────────────────────────────────────────────────────────
    // Task 2: Distance calculation accuracy
    // ──────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Should check in when user is within 50m of POI")
    void shouldCheckIn_WhenWithin50Meters() {
        // Arrange: POI at Istanbul Taksim (41.0370, 28.9850)
        // User at ~30m away
        UUID poiId = UUID.randomUUID();
        PointOfInterest poi = PointOfInterest.builder()
                .poiId(poiId)
                .name("Taksim Square")
                .category("landmark")
                .latitude(41.0370)
                .longitude(28.9850)
                .build();

        AutoCheckInRequestDTO request = new AutoCheckInRequestDTO(
                41.03720, 28.98510, List.of(poiId));

        when(poiRepository.findAllById(List.of(poiId))).thenReturn(List.of(poi));
        when(checkInRepository.existsByUserAndPointOfInterest(testUser, poi)).thenReturn(false);
        when(checkInRepository.save(any(CheckIn.class))).thenAnswer(inv -> {
            CheckIn saved = inv.getArgument(0);
            saved.setCheckInId(UUID.randomUUID());
            saved.setCheckedInAt(Instant.now());
            return saved;
        });

        // Act
        CheckInResponseDTO result = checkInService.evaluateAutoCheckIn(testUser, request);

        // Assert
        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getMessage()).isEqualTo("Successfully checked in");
        assertThat(result.getPoiName()).isEqualTo("Taksim Square");
        assertThat(result.getCheckInId()).isNotNull();
        verify(checkInRepository).save(any(CheckIn.class));
    }

    @Test
    @DisplayName("Should NOT check in when user is more than 50m from POI")
    void shouldNotCheckIn_WhenOutside50Meters() {
        // Arrange: POI at Taksim, user ~500m away at Galata
        UUID poiId = UUID.randomUUID();
        PointOfInterest poi = PointOfInterest.builder()
                .poiId(poiId)
                .name("Taksim Square")
                .category("landmark")
                .latitude(41.0370)
                .longitude(28.9850)
                .build();

        AutoCheckInRequestDTO request = new AutoCheckInRequestDTO(
                41.0256, 28.9742, List.of(poiId)); // Galata Tower area (~500m away)

        when(poiRepository.findAllById(List.of(poiId))).thenReturn(List.of(poi));

        // Act
        CheckInResponseDTO result = checkInService.evaluateAutoCheckIn(testUser, request);

        // Assert
        assertThat(result.isSuccess()).isFalse();
        assertThat(result.getMessage()).contains("No valid POI found within");
        verify(checkInRepository, never()).save(any(CheckIn.class));
    }

    @Test
    @DisplayName("Should select closest POI when multiple are within range")
    void shouldSelectClosestPoi_WhenMultipleInRange() {
        // Arrange: two POIs, user closer to the second one
        UUID poiId1 = UUID.randomUUID();
        UUID poiId2 = UUID.randomUUID();

        PointOfInterest poi1 = PointOfInterest.builder()
                .poiId(poiId1)
                .name("Cafe A (40m away)")
                .category("cafe")
                .latitude(41.03730)
                .longitude(28.98510)
                .build();

        PointOfInterest poi2 = PointOfInterest.builder()
                .poiId(poiId2)
                .name("Cafe B (10m away)")
                .category("cafe")
                .latitude(41.03705)
                .longitude(28.98505)
                .build();

        // User position: very close to poi2
        AutoCheckInRequestDTO request = new AutoCheckInRequestDTO(
                41.03700, 28.98500, List.of(poiId1, poiId2));

        when(poiRepository.findAllById(List.of(poiId1, poiId2))).thenReturn(List.of(poi1, poi2));
        when(checkInRepository.existsByUserAndPointOfInterest(testUser, poi2)).thenReturn(false);
        when(checkInRepository.save(any(CheckIn.class))).thenAnswer(inv -> {
            CheckIn saved = inv.getArgument(0);
            saved.setCheckInId(UUID.randomUUID());
            saved.setCheckedInAt(Instant.now());
            return saved;
        });

        // Act
        CheckInResponseDTO result = checkInService.evaluateAutoCheckIn(testUser, request);

        // Assert
        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getPoiName()).isEqualTo("Cafe B (10m away)");
    }

    // ──────────────────────────────────────────────────────────────
    // Task 1 & 3: Duplicate check-in prevention
    // ──────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Duplicate check-in should return descriptive message without error")
    void shouldReturnMessage_WhenDuplicateCheckIn() {
        // Arrange
        UUID poiId = UUID.randomUUID();
        PointOfInterest poi = PointOfInterest.builder()
                .poiId(poiId)
                .name("Taksim Square")
                .category("landmark")
                .latitude(41.0370)
                .longitude(28.9850)
                .build();

        AutoCheckInRequestDTO request = new AutoCheckInRequestDTO(
                41.03700, 28.98500, List.of(poiId));

        when(poiRepository.findAllById(List.of(poiId))).thenReturn(List.of(poi));
        when(checkInRepository.existsByUserAndPointOfInterest(testUser, poi)).thenReturn(true);

        // Act
        CheckInResponseDTO result = checkInService.evaluateAutoCheckIn(testUser, request);

        // Assert: returns descriptive message without error, as per acceptance criteria
        assertThat(result.getMessage()).isEqualTo("Already checked in");
        assertThat(result.getPoiId()).isEqualTo(poiId);
        assertThat(result.getPoiName()).isEqualTo("Taksim Square");
        verify(checkInRepository, never()).save(any(CheckIn.class));
    }

    // ──────────────────────────────────────────────────────────────
    // Edge cases
    // ──────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Should fail gracefully with empty candidate list")
    void shouldFail_WhenNoCandidates() {
        AutoCheckInRequestDTO request = new AutoCheckInRequestDTO(
                41.0370, 28.9850, Collections.emptyList());

        CheckInResponseDTO result = checkInService.evaluateAutoCheckIn(testUser, request);

        assertThat(result.isSuccess()).isFalse();
        assertThat(result.getMessage()).isEqualTo("No candidate POIs provided");
        verify(poiRepository, never()).findAllById(any());
    }

    @Test
    @DisplayName("Should fail gracefully with null candidate list")
    void shouldFail_WhenNullCandidates() {
        AutoCheckInRequestDTO request = new AutoCheckInRequestDTO(41.0370, 28.9850, null);

        CheckInResponseDTO result = checkInService.evaluateAutoCheckIn(testUser, request);

        assertThat(result.isSuccess()).isFalse();
        assertThat(result.getMessage()).isEqualTo("No candidate POIs provided");
    }

    @Test
    @DisplayName("Should fail when candidate POI IDs don't exist in DB")
    void shouldFail_WhenPoiIdsNotFoundInDb() {
        UUID fakePoiId = UUID.randomUUID();
        AutoCheckInRequestDTO request = new AutoCheckInRequestDTO(
                41.0370, 28.9850, List.of(fakePoiId));

        when(poiRepository.findAllById(List.of(fakePoiId))).thenReturn(Collections.emptyList());

        CheckInResponseDTO result = checkInService.evaluateAutoCheckIn(testUser, request);

        assertThat(result.isSuccess()).isFalse();
        assertThat(result.getMessage()).contains("No valid POI found");
    }

    @Test
    @DisplayName("Saved check-in should use AUTO source")
    void savedCheckIn_ShouldUseAutoSource() {
        UUID poiId = UUID.randomUUID();
        PointOfInterest poi = PointOfInterest.builder()
                .poiId(poiId)
                .name("Test POI")
                .category("test")
                .latitude(41.0370)
                .longitude(28.9850)
                .build();

        AutoCheckInRequestDTO request = new AutoCheckInRequestDTO(
                41.03700, 28.98500, List.of(poiId));

        when(poiRepository.findAllById(List.of(poiId))).thenReturn(List.of(poi));
        when(checkInRepository.existsByUserAndPointOfInterest(testUser, poi)).thenReturn(false);
        when(checkInRepository.save(any(CheckIn.class))).thenAnswer(inv -> {
            CheckIn saved = inv.getArgument(0);
            saved.setCheckInId(UUID.randomUUID());
            saved.setCheckedInAt(Instant.now());
            return saved;
        });

        checkInService.evaluateAutoCheckIn(testUser, request);

        verify(checkInRepository).save(argThat(checkIn -> checkIn.getSource() == CheckInSource.AUTO &&
                checkIn.getUser().equals(testUser) &&
                checkIn.getPointOfInterest().equals(poi)));
    }
}
