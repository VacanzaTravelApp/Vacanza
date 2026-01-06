package com.vacanza.backend.service;

import com.vacanza.backend.dto.response.UserLoginResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserInfo;
import com.vacanza.backend.repo.UserInfoRepository;
import com.vacanza.backend.repo.UserRepository;
import com.vacanza.backend.security.CurrentUserProvider;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * User service:
 * Reads current user from SecurityContext via CurrentUserProvider
 * Maps to DTO expected by frontend
 */
@Service
public class UserService {

    private final UserRepository userRepository;
    private final UserInfoRepository userInfoRepository;
    private final CurrentUserProvider currentUserProvider;

    public UserService(UserRepository userRepository,
                       UserInfoRepository userInfoRepository,
                       CurrentUserProvider currentUserProvider) {
        this.userRepository = userRepository;
        this.userInfoRepository = userInfoRepository;
        this.currentUserProvider = currentUserProvider;
    }

    public List<UserLoginResponseDTO> getAllUsers() {
        return userRepository.findAll()
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public UserLoginResponseDTO getCurrentUser() {
        User user = currentUserProvider.getCurrentUserEntity();
        return toResponse(user);
    }

    private UserLoginResponseDTO toResponse(User user) {
        boolean profileCompleted = userInfoRepository.existsByUser(user);

        //if profile exists, use displayName from UserInfo; otherwise fallback to email
        String displayName = user.getEmail();
        UserInfo info = userInfoRepository.findByUser(user).orElse(null);
        if (info != null) {
            displayName = info.getDisplayName();
        }

        return UserLoginResponseDTO.builder()
                .authenticated(true)
                .user(UserLoginResponseDTO.UserInfo.builder()
                        .userId(user.getUserId())
                        .email(user.getEmail())
                        .displayName(displayName)
                        .build())
                .build();
        //if we want to add sth in this DTO we can extend it
    }
}
