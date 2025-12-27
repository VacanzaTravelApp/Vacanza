package com.vacanza.backend.service.impl;

import com.vacanza.backend.dto.response.UserLoginHistoryResponseDTO;

import java.util.List;

public interface UserLoginHistoryImpl {
    List<UserLoginHistoryResponseDTO> getAllLoginHistories();

    List<UserLoginHistoryResponseDTO> getMyLoginHistories();
}
