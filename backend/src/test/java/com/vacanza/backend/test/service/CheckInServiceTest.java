package com.vacanza.backend.test.service;

import com.vacanza.backend.dto.request.AutoCheckInRequestDTO;
import com.vacanza.backend.dto.response.CheckInResponseDTO;
import com.vacanza.backend.entity.CheckIn;
import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.enums.CheckInSource;
import com.vacanza.backend.event.CheckInCompletedEvent;
import com.vacanza.backend.repo.CheckInRepository;
import com.vacanza.backend.repo.PointOfInterestRepository;
import com.vacanza.backend.service.CheckInService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

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

        @Mock
        private ApplicationEventPublisher eventPublisher;

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

                CheckInResponseDTO result = checkInService.evaluateAutoCheckIn(testUser, request);

                assertThat(result.isSuccess()).isTrue();
                assertThat(result.getMessage()).isEqualTo("Successfully checked in");
                assertThat(result.getPoiName()).isEqualTo("Taksim Square");
                assertThat(result.getCheckInId()).isNotNull();
                verify(checkInRepository).save(any(CheckIn.class));
        }

        @Test
        @DisplayName("Should NOT check in when user is more than 50m from POI")
        void shouldNotCheckIn_WhenOutside50Meters() {
                UUID poiId = UUID.randomUUID();
                PointOfInterest poi = PointOfInterest.builder()
                                .poiId(poiId)
                                .name("Taksim Square")
                                .category("landmark")
                                .latitude(41.0370)
                                .longitude(28.9850)
                                .build();

                AutoCheckInRequestDTO request = new AutoCheckInRequestDTO(
                                41.0256, 28.9742, List.of(poiId));

                when(poiRepository.findAllById(List.of(poiId))).thenReturn(List.of(poi));

                CheckInResponseDTO result = checkInService.evaluateAutoCheckIn(testUser, request);

                assertThat(result.isSuccess()).isFalse();
                assertThat(result.getMessage()).contains("No valid POI found within");
                verify(checkInRepository, never()).save(any(CheckIn.class));
        }

        @Test
        @DisplayName("Should select closest POI when multiple are within range")
        void shouldSelectClosestPoi_WhenMultipleInRange() {
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

                CheckInResponseDTO result = checkInService.evaluateAutoCheckIn(testUser, request);

                assertThat(result.isSuccess()).isTrue();
                assertThat(result.getPoiName()).isEqualTo("Cafe B (10m away)");
        }

        // ──────────────────────────────────────────────────────────────
        // Task 1 & 3: Duplicate check-in prevention
        // ──────────────────────────────────────────────────────────────

        @Test
        @DisplayName("Duplicate check-in should return descriptive message without error")
        void shouldReturnMessage_WhenDuplicateCheckIn() {
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

                CheckInResponseDTO result = checkInService.evaluateAutoCheckIn(testUser, request);

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

        // ──────────────────────────────────────────────────────────────
        // Gamification event publishing (VACANZA-235)
        // ──────────────────────────────────────────────────────────────

        @Test
        @DisplayName("Should publish CheckInCompletedEvent after successful check-in")
        void shouldPublishEvent_WhenCheckInSucceeds() {
                UUID poiId = UUID.randomUUID();
                PointOfInterest poi = PointOfInterest.builder()
                                .poiId(poiId)
                                .name("Event Test POI")
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

                CheckInResponseDTO result = checkInService.evaluateAutoCheckIn(testUser, request);

                ArgumentCaptor<CheckInCompletedEvent> eventCaptor = ArgumentCaptor
                                .forClass(CheckInCompletedEvent.class);
                verify(eventPublisher).publishEvent(eventCaptor.capture());

                CheckInCompletedEvent event = eventCaptor.getValue();
                assertThat(event.getUserId()).isEqualTo(testUser.getUserId());
                assertThat(event.getPoiId()).isEqualTo(poiId);
                assertThat(event.getPoiName()).isEqualTo("Event Test POI");
                assertThat(event.getSource()).isEqualTo(CheckInSource.AUTO);
                assertThat(event.getCheckInId()).isNotNull();

                assertThat(result.isGamificationTriggered()).isTrue();
        }

        @Test
        @DisplayName("Should NOT publish event when check-in is duplicate")
        void shouldNotPublishEvent_WhenDuplicateCheckIn() {
                UUID poiId = UUID.randomUUID();
                PointOfInterest poi = PointOfInterest.builder()
                                .poiId(poiId)
                                .name("Duplicate POI")
                                .category("test")
                                .latitude(41.0370)
                                .longitude(28.9850)
                                .build();

                AutoCheckInRequestDTO request = new AutoCheckInRequestDTO(
                                41.03700, 28.98500, List.of(poiId));

                when(poiRepository.findAllById(List.of(poiId))).thenReturn(List.of(poi));
                when(checkInRepository.existsByUserAndPointOfInterest(testUser, poi)).thenReturn(true);

                CheckInResponseDTO result = checkInService.evaluateAutoCheckIn(testUser, request);

                verify(eventPublisher, never()).publishEvent(any(CheckInCompletedEvent.class));
                assertThat(result.isGamificationTriggered()).isFalse();
        }

        @Test
        @DisplayName("Should NOT publish event when no candidates provided")
        void shouldNotPublishEvent_WhenNoCandidates() {
                AutoCheckInRequestDTO request = new AutoCheckInRequestDTO(
                                41.0370, 28.9850, Collections.emptyList());

                checkInService.evaluateAutoCheckIn(testUser, request);

                verify(eventPublisher, never()).publishEvent(any(CheckInCompletedEvent.class));
        }
}
