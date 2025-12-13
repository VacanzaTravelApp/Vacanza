package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.UserInfoRequestDTO;
import com.vacanza.backend.dto.response.UserInfoResponseDTO;
import com.vacanza.backend.dto.response.UserLoginResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserInfo;
import com.vacanza.backend.exceptions.enums.UserExceptionEnum;
import com.vacanza.backend.exceptions.enums.UserInfoExceptionEnum;
import com.vacanza.backend.repo.UserInfoRepository;
import com.vacanza.backend.repo.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.vacanza.backend.service.impl.UserInfoImpl;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserInfoService implements UserInfoImpl {

    private final UserInfoRepository userInfoRepository;
    private final UserRepository userRepository;

    @Override
    @Transactional(readOnly = true)
    public UserInfoResponseDTO getUserInfo() {

        User currentUser = getCurrentAuthenticatedUser();

        //  Get the profile
        UserInfo userInfo = userInfoRepository.findByUser(currentUser)
                .orElseThrow(() -> new RuntimeException(UserInfoExceptionEnum.PROFILE_NOT_FOUND.getExplanation()));

        // Map to DTO
        return mapToResponseDTO(userInfo);

    }

    @Override
    @Transactional
    public UserInfoResponseDTO updateUserInfo(UserInfoRequestDTO request) {

        // Get the user
        User currentUser = getCurrentAuthenticatedUser();

        //  Find or Create Profile
        UserInfo userInfo = userInfoRepository.findByUser(currentUser)
                .orElse(new UserInfo());

        // Update Entity Fields
        if (userInfo.getUser() == null) {
            userInfo.setUser(currentUser);
        }
        userInfo.setFirstName(request.getFirstName());
        userInfo.setMiddleName(request.getMiddleName());
        userInfo.setLastName(request.getLastName());
        userInfo.setPreferredName(request.getPreferredName());
        userInfo.setCountry(request.getCountry());
        userInfo.setBirthDate(request.getBirthDate());
        userInfo.setGender(request.getGender());
        userInfo.setBudget(request.getBudget());
        userInfo.setProfileImageUrl(request.getProfileImageUrl());

        // Save
        UserInfo savedInfo = userInfoRepository.save(userInfo);

        // Return DTO using Builder
        return mapToResponseDTO(savedInfo);
    }

    private UserInfoResponseDTO mapToResponseDTO(UserInfo info) {
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

    private User getCurrentAuthenticatedUser() {
        String firebaseUid = (String) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        return userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException(UserInfoExceptionEnum.USER_NOT_FOUND.getExplanation()));
    }
}








