package com.vacanza.backend.test.event;

import com.vacanza.backend.entity.enums.CheckInSource;
import com.vacanza.backend.event.CheckInCompletedEvent;
import com.vacanza.backend.event.GamificationEventListener;
import com.vacanza.backend.service.GamificationService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GamificationEventListenerTest {

    @Mock
    private GamificationService gamificationService;

    @InjectMocks
    private GamificationEventListener listener;

    private CheckInCompletedEvent sampleEvent() {
        return CheckInCompletedEvent.builder()
                .checkInId(UUID.randomUUID())
                .userId(UUID.randomUUID())
                .poiId(UUID.randomUUID())
                .poiName("Taksim Square")
                .checkedInAt(Instant.now())
                .source(CheckInSource.AUTO)
                .build();
    }

    @Test
    @DisplayName("Should call gamification service when event is received")
    void shouldCallGamificationService_OnEvent() {
        CheckInCompletedEvent event = sampleEvent();

        listener.onCheckInCompleted(event);

        verify(gamificationService).processCheckIn(event);
    }

    @Test
    @DisplayName("Should log and swallow exception when gamification service fails")
    void shouldLogAndSwallow_WhenGamificationFails() {
        CheckInCompletedEvent event = sampleEvent();
        doThrow(new RuntimeException("Gamification API unavailable"))
                .when(gamificationService).processCheckIn(event);

        assertThatCode(() -> listener.onCheckInCompleted(event))
                .doesNotThrowAnyException();

        verify(gamificationService).processCheckIn(event);
    }
}
