package com.vacanza.backend.service;


import com.vacanza.backend.dto.request.UserLoginRequestDTO;
import com.vacanza.backend.dto.response.UserLoginHistoryResponseDTO;
import com.vacanza.backend.dto.response.UserLoginResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.exceptions.enums.LoginHistoryExceptionEnum;
import com.vacanza.backend.exceptions.enums.UserExceptionEnum;
import com.vacanza.backend.repo.UserRepository;
import com.vacanza.backend.service.impl.UserImpl;
import jdk.jshell.spi.ExecutionControl;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    /*@Transactional
    public User addNewUser(UserLoginRequestDTO request) {


        if(request.getEmail() == null){
            throw new RuntimeException(UserExceptionEnum.EMAIL_NOT_VERIFIED.getExplanation());
        }

        else{

            User newUser = new User();
            newUser.setEmail(request.getEmail());
        }

        newUser.setFirebaseUid(request.getFirebaseUid());

        newUser.setName(request.getName());
        newUser.setRole(request.getRole());   // Optional: validate role
        newUser.setVerified(false);           // or true if Firebase emailVerified claim is used
        newUser.setJoinDate(Instant.now());

        // 6. Save to DB
        return userRepository.save(newUser);
    }*/

}
