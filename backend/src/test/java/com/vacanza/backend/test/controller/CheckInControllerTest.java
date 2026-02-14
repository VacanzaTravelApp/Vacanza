package com.vacanza.backend.test.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.controller.CheckInController;
import com.vacanza.backend.dto.request.AutoCheckInRequestDTO;
import com.vacanza.backend.dto.response.CheckInResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.CheckInService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = CheckInController.class, excludeFilters = @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE, classes = com.vacanza.backend.security.FirebaseTokenFilter.class))
@AutoConfigureMockMvc(addFilters = false)
public class CheckInControllerTest {

        @Autowired
        private MockMvc mockMvc;

        @MockBean
        private CheckInService checkInService;

        @MockBean
        private CurrentUserProvider currentUserProvider;

        @Autowired
        private ObjectMapper objectMapper;

        @Test
        public void testAutoCheckIn_Success() throws Exception {
                User mockUser = new User();
                mockUser.setUserId(UUID.randomUUID());

                AutoCheckInRequestDTO requestDTO = new AutoCheckInRequestDTO(40.0, 29.0, List.of(UUID.randomUUID()));
                CheckInResponseDTO responseDTO = CheckInResponseDTO.builder()
                                .success(true)
                                .message("Successfully checked in")
                                .poiName("Test POI")
                                .build();

                when(currentUserProvider.getCurrentUserEntity()).thenReturn(mockUser);
                when(checkInService.evaluateAutoCheckIn(any(User.class), any(AutoCheckInRequestDTO.class)))
                                .thenReturn(responseDTO);

                mockMvc.perform(post("/checkins/auto")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(requestDTO))
                                .with(csrf()))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.success").value(true))
                                .andExpect(jsonPath("$.message").value("Successfully checked in"))
                                .andExpect(jsonPath("$.poiName").value("Test POI"));
        }
}
