package com.vacanza.backend.service;

import com.vacanza.backend.dto.response.UserInfoResponseDTO;
import com.vacanza.backend.dto.response.UserLoginResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserInfo;
import com.vacanza.backend.exceptions.enums.UserExceptionEnum;
import com.vacanza.backend.repo.UserInfoRepository;
import com.vacanza.backend.repo.UserRepository;
import com.vacanza.backend.service.impl.UserInfoImpl;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserInfoService implements UserInfoImpl {

    private final UserInfoRepository userInfoRepository;
    private final UserRepository userRepository;
    private final UserService userService;




}
