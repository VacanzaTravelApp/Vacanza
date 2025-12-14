package com.vacanza.backend.service.impl;

import com.vacanza.backend.dto.response.UserAuthenticationDTO;
import jakarta.servlet.http.HttpServletRequest;

public interface AuthImpl {
    UserAuthenticationDTO getMe(HttpServletRequest request);
    //UserRegisterResponseDTO onboard(UserRegisterRequestDTO req);
}
