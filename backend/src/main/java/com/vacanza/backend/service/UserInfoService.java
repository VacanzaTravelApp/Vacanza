package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.UserInfoRequestDTO;
import com.vacanza.backend.dto.response.UserInfoResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserInfo;
import com.vacanza.backend.repo.UserInfoRepository;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.impl.UserInfoImpl;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/**
 * Profile upsert:
 * - if user_info doesn't exist: requires firstName + lastName, then create
 * - if exists: updates only non-null fields (doesn't overwrite required with null)
 */
@Service
@AllArgsConstructor
public class UserInfoService implements UserInfoImpl {

    private final CurrentUserProvider currentUserProvider;
    private final UserInfoRepository userInfoRepository;

    @Override
    @Transactional(readOnly = true)
    public UserInfoResponseDTO getUserInfo() {
        User user = currentUserProvider.getCurrentUserEntity();
        UserInfo info = userInfoRepository.findByUser(user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User profile not found"));

        return toDto(info);
    }

    @Override
    @Transactional
    public UserInfoResponseDTO updateUserInfo(UserInfoRequestDTO req) {
        User user = currentUserProvider.getCurrentUserEntity();

        UserInfo info = userInfoRepository.findByUser(user).orElse(null);

        // Create (first time onboarding) requires mandatory fields
        if (info == null) {
            if (isBlank(req.getFirstName()) || isBlank(req.getLastName())) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "firstName and lastName are required to create profile"
                );
            }

            info = UserInfo.builder()
                    .user(user)
                    .firstName(req.getFirstName().trim())
                    .lastName(req.getLastName().trim())
                    .middleName(req.getMiddleName())
                    .preferredName(req.getPreferredName())
                    .country(req.getCountry())
                    .birthDate(req.getBirthDate())
                    .gender(req.getGender())
                    .budget(req.getBudget())
                    .profileImageUrl(req.getProfileImageUrl())
                    .build();

            return toDto(userInfoRepository.save(info));
        }

        // Update: only apply non-null values (do not overwrite with null)
        if (req.getFirstName() != null) info.setFirstName(req.getFirstName().trim());
        if (req.getLastName() != null) info.setLastName(req.getLastName().trim());
        if (req.getMiddleName() != null) info.setMiddleName(req.getMiddleName());
        if (req.getPreferredName() != null) info.setPreferredName(req.getPreferredName());

        if (req.getCountry() != null) info.setCountry(req.getCountry());
        if (req.getBirthDate() != null) info.setBirthDate(req.getBirthDate());
        if (req.getGender() != null) info.setGender(req.getGender());
        if (req.getBudget() != null) info.setBudget(req.getBudget());
        if (req.getProfileImageUrl() != null) info.setProfileImageUrl(req.getProfileImageUrl());

        return toDto(userInfoRepository.save(info));
    }

    private UserInfoResponseDTO toDto(UserInfo info) {
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

    private boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
