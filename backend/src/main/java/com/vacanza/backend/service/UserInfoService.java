package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.UserInfoRequestDTO;
import com.vacanza.backend.dto.response.UserInfoResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserInfo;
import com.vacanza.backend.repo.UserInfoRepository;
import com.vacanza.backend.security.CurrentUserProvider;

import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.Instant;

/**
 * Profile service for UserInfo.
 * Creates profile if not exists, updates otherwise.
 */
@Service
public class UserInfoService {

    private final UserInfoRepository userInfoRepository;
    private final CurrentUserProvider currentUserProvider;

    public UserInfoService(UserInfoRepository userInfoRepository,
                           CurrentUserProvider currentUserProvider) {
        this.userInfoRepository = userInfoRepository;
        this.currentUserProvider = currentUserProvider;
    }

    public UserInfoResponseDTO getUserInfo() {
        User user = currentUserProvider.getCurrentUserEntity();

        UserInfo info = userInfoRepository.findByUser(user)
                .orElseThrow(() -> new IllegalStateException("User profile not found"));

        return toResponse(info);
    }

    public UserInfoResponseDTO updateUserInfo(UserInfoRequestDTO request) {
        User user = currentUserProvider.getCurrentUserEntity();

        UserInfo info = userInfoRepository.findByUser(user).orElse(null);

        if (info == null) {
            // Creating new profile -> DB has NOT NULL first/last name constraints
            if (!StringUtils.hasText(request.getFirstName()) || !StringUtils.hasText(request.getLastName())) {
                throw new IllegalArgumentException("firstName and lastName are required to create profile");
            }

            info = UserInfo.builder()
                    .user(user)
                    .firstName(request.getFirstName())
                    .middleName(request.getMiddleName())
                    .lastName(request.getLastName())
                    .preferredName(request.getPreferredName())
                    .country(request.getCountry())
                    .birthDate(request.getBirthDate())
                    .gender(request.getGender())
                    .budget(request.getBudget())
                    .profileImageUrl(request.getProfileImageUrl())
                    .joinDate(Instant.now())
                    .build();
        } else {
            // Update strategy: overwrite if provided (simple + safe)
            if (StringUtils.hasText(request.getFirstName())) info.setFirstName(request.getFirstName());
            info.setMiddleName(request.getMiddleName());
            if (StringUtils.hasText(request.getLastName())) info.setLastName(request.getLastName());
            info.setPreferredName(request.getPreferredName());

            info.setCountry(request.getCountry());
            info.setBirthDate(request.getBirthDate());
            info.setGender(request.getGender());
            info.setBudget(request.getBudget());
            info.setProfileImageUrl(request.getProfileImageUrl());
        }

        UserInfo saved = userInfoRepository.save(info);
        return toResponse(saved);
    }

    private UserInfoResponseDTO toResponse(UserInfo info) {
        return UserInfoResponseDTO.builder()
                .infoId(info.getInfoId())
                .userId(info.getUser().getUserId())
                .firstName(info.getFirstName())
                .middleName(info.getMiddleName())
                .lastName(info.getLastName())
                .preferredName(info.getPreferredName())
                .displayName(info.getDisplayName())
                .country(info.getCountry())
                .birthDate(info.getBirthDate())
                .gender(info.getGender())
                .budget(info.getBudget())
                .profileImageUrl(info.getProfileImageUrl())
                .joinDate(info.getJoinDate())
                .build();
    }
}
