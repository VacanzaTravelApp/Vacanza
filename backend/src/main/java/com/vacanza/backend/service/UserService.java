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
                .map(user -> UserLoginResponseDTO.builder()
                        .authenticated(true)
                        .user(
                                UserLoginResponseDTO.UserInfo.builder()
                                        .userId(user.getUserId())
                                        .email(user.getEmail())
                                        .role(user.getRole().name())
                                        .build()
                        )
                        .build()
                )
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public UserLoginResponseDTO getCurrentUser() {

        String firebaseUid = (String)SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() ->
                        new RuntimeException(UserExceptionEnum.USER_NOT_FOUND.getExplanation())
                );

        return UserLoginResponseDTO.builder()
                .authenticated(true)
                .user(
                        UserLoginResponseDTO.UserInfo.builder()
                                .userId(user.getUserId())
                                .email(user.getEmail())
                                .role(user.getRole().name())
                                .build()
                )
                .build();
    }

    @Transactional
    public User addNewUser(UserLoginRequestDTO request) {

        // Get Firebase UID (set by FirebaseTokenFilter)
        String firebaseUid = (String) SecurityContextHolder
                .getContext()
                .getAuthentication()
                .getPrincipal();

        // Prevent duplicate users (important)
        if (userRepository.existsByFirebaseUid(firebaseUid)) {
            return userRepository.findByFirebaseUid(firebaseUid)
                    .orElseThrow(); // idempotent behavior
        }


        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException(
                    UserExceptionEnum.EMAIL_ALREADY_EXIST.getExplanation()
            );
        }

        // Create user
        User user = new User();
        user.setFirebaseUid(firebaseUid);
        user.setEmail(request.getEmail());
        user.setRole(Role.USER);
        user.setCreatedAt(Instant.now());

        return userRepository.save(user);
    }

}
