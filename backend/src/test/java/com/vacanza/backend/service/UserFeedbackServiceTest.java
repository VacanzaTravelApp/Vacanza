package com.vacanza.backend.service;

import com.vacanza.backend.config.PoiFeedbackProperties;
import com.vacanza.backend.dto.internal.PoiFeedbackContext;
import com.vacanza.backend.dto.request.PoiFeedbackEventRequestDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserPoiFeedback;
import com.vacanza.backend.repo.UserCategoryAffinityRepository;
import com.vacanza.backend.repo.UserPoiFeedbackRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserFeedbackServiceTest {

    @Mock
    private UserPoiFeedbackRepository poiFeedbackRepository;

    @Mock
    private UserCategoryAffinityRepository categoryAffinityRepository;

    @Test
    void recordThumbsUpUpsertsPoiKey() {
        PoiFeedbackProperties props = new PoiFeedbackProperties();
        UserFeedbackService svc = new UserFeedbackService(props, poiFeedbackRepository, categoryAffinityRepository);
        User user = User.builder().userId(UUID.randomUUID()).build();
        when(poiFeedbackRepository.findByUser_UserIdAndPoiKey(user.getUserId(), "fs:abc"))
                .thenReturn(Optional.empty());

        svc.record(
                user,
                new PoiFeedbackEventRequestDTO("THUMBS_UP", null, "abc", null, null, null, null));

        ArgumentCaptor<UserPoiFeedback> cap = ArgumentCaptor.forClass(UserPoiFeedback.class);
        verify(poiFeedbackRepository).save(cap.capture());
        assertEquals(2.0, cap.getValue().getScore(), 1e-9);
        assertEquals("fs:abc", cap.getValue().getPoiKey());
    }

    @Test
    void recordThumbsUpUsesWaypointKeyWhenNoVendorIds() {
        PoiFeedbackProperties props = new PoiFeedbackProperties();
        UserFeedbackService svc = new UserFeedbackService(props, poiFeedbackRepository, categoryAffinityRepository);
        User user = User.builder().userId(UUID.randomUUID()).build();
        String wpKey = "wp:72a2fb86addfedd2";
        when(poiFeedbackRepository.findByUser_UserIdAndPoiKey(user.getUserId(), wpKey))
                .thenReturn(Optional.empty());

        svc.record(
                user,
                new PoiFeedbackEventRequestDTO(
                        "THUMBS_UP",
                        null,
                        null,
                        null,
                        "Ayasofya",
                        41.0086,
                        28.9802));

        ArgumentCaptor<UserPoiFeedback> cap = ArgumentCaptor.forClass(UserPoiFeedback.class);
        verify(poiFeedbackRepository).save(cap.capture());
        assertEquals(2.0, cap.getValue().getScore(), 1e-9);
        assertEquals(wpKey, cap.getValue().getPoiKey());
    }

    @Test
    void recordThumbsDownDeletesPoiRowWhenScoreHitsZero() {
        PoiFeedbackProperties props = new PoiFeedbackProperties();
        UserFeedbackService svc = new UserFeedbackService(props, poiFeedbackRepository, categoryAffinityRepository);
        User user = User.builder().userId(UUID.randomUUID()).build();
        UserPoiFeedback existing = UserPoiFeedback.builder()
                .user(user)
                .poiKey("fs:abc")
                .score(2.0)
                .build();
        when(poiFeedbackRepository.findByUser_UserIdAndPoiKey(user.getUserId(), "fs:abc"))
                .thenReturn(Optional.of(existing));

        svc.record(
                user,
                new PoiFeedbackEventRequestDTO("THUMBS_DOWN", null, "abc", null, null, null, null));

        verify(poiFeedbackRepository).delete(existing);
        verify(poiFeedbackRepository, never()).save(any());
    }

    @Test
    void buildContextEmptyWhenDisabled() {
        PoiFeedbackProperties p = new PoiFeedbackProperties();
        p.setEnabled(false);
        UserFeedbackService svc = new UserFeedbackService(p, poiFeedbackRepository, categoryAffinityRepository);
        PoiFeedbackContext ctx = svc.buildContext(UUID.randomUUID());
        assertTrue(ctx.isEmpty());
    }
}
