package com.vacanza.backend.service.impl;

import com.vacanza.backend.dto.AutoCheckInRequestDTO;
import com.vacanza.backend.dto.CheckInResponseDTO;
import com.vacanza.backend.entity.User;

public interface CheckInImpl {
    CheckInResponseDTO evaluateAutoCheckIn(User user, AutoCheckInRequestDTO request);
}
