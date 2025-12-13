package com.vacanza.backend.service.impl;

import com.vacanza.backend.dto.request.UserInfoRequestDTO;
import com.vacanza.backend.dto.response.UserInfoResponseDTO;

public interface UserInfoImpl {

    UserInfoResponseDTO getUserInfo();

    UserInfoResponseDTO updateUserInfo(UserInfoRequestDTO request);
}
