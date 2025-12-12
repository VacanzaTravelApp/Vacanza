package com.vacanza.backend.service;


import com.vacanza.backend.dto.request.UserLoginRequestDTO;
import com.vacanza.backend.dto.response.UserLoginHistoryResponseDTO;
import com.vacanza.backend.dto.response.UserLoginResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.enums.Role;
import com.vacanza.backend.exceptions.enums.UserLoginHistoryExceptionEnum;
import com.vacanza.backend.exceptions.enums.UserExceptionEnum;
import com.vacanza.backend.repo.UserRepository;
import com.vacanza.backend.service.impl.UserImpl;
import jdk.jshell.spi.ExecutionControl;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class UserService implements UserImpl {

    private final UserRepository userRepository;


    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }


    public List<UserLoginResponseDTO> getAllUsers() {

        return userRepository.findAll()
                .stream()
                .map(item -> UserLoginResponseDTO.builder()
                        .user(
                                UserLoginResponseDTO.UserInfo.builder()
                                        .userId(item.getUserId())
                                        .email(item.getEmail())
                                        .role(String.valueOf(item.getRole()))
                                        //.verified(item.isVerified())
                                        .build()
                        )
                        .build()
                )
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public UserLoginResponseDTO getUserByUserId(UUID userId) {

        User user = userRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException(UserExceptionEnum.USER_NOT_FOUND.getExplanation()));

        return UserLoginResponseDTO.builder()
                .authenticated(true)
                .user(UserLoginResponseDTO.UserInfo.builder()
                        .userId(user.getUserId())
                        .email(user.getEmail())
                        .role(String.valueOf(user.getRole()))
                        //.verified(user.isVerified())
                        .build()
                )
                .build();
    }

    @Transactional
    public User addNewUser(UserLoginRequestDTO request) {

    if(userRepository.existsByEmail(request.getEmail())) {
        throw new RuntimeException(UserExceptionEnum.EMAIL_ALREADY_EXIST.getExplanation());
    }else{
        User user = new User();
        user.setEmail(request.getEmail());
        user.setFirebaseUid(user.getFirebaseUid());
        user.setRole(Role.USER);
        user.setCreatedAt(Instant.now());

        return  userRepository.save(user);

        }

    }

}
