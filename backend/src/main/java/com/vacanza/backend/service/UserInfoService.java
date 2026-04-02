package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.UserInfoRequestDTO;
import com.vacanza.backend.dto.response.UserInfoResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserInfo;
import com.vacanza.backend.repo.UserInfoRepository;
import com.vacanza.backend.security.CurrentUserProvider;

import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.util.Map;

/**
 * Profile upsert:
 * - if user_info doesn't exist: requires firstName + lastName, then create
 * - if exists: updates only non-null fields (doesn't overwrite required with
 * null)
 */
@Service
@AllArgsConstructor
public class UserInfoService {

    private final CurrentUserProvider currentUserProvider;
    private final UserInfoRepository userInfoRepository;

    @Transactional(readOnly = true)
    public UserInfoResponseDTO getUserInfo() {
        User user = currentUserProvider.getCurrentUserEntity();
        UserInfo info = userInfoRepository.findByUser(user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User profile not found"));

        return toDto(info);
    }

    /**
     * Get user profile by User entity (for internal use, e.g. chat proxy).
     * Returns empty if profile not found.
     */
    @Transactional(readOnly = true)
    public java.util.Optional<UserInfoResponseDTO> getUserInfoByUser(User user) {
        return userInfoRepository.findByUser(user).map(this::toDto);
    }

    @Transactional
    public UserInfoResponseDTO updateUserInfo(UserInfoRequestDTO req) {
        User user = currentUserProvider.getCurrentUserEntity();

        UserInfo info = userInfoRepository.findByUser(user).orElse(null);

        // Create (first time onboarding) requires mandatory fields
        if (info == null) {
            if (isBlank(req.getFirstName()) || isBlank(req.getLastName())) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "firstName and lastName are required to create profile");
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
                    .profileImageUrl(req.getProfileImageUrl())
                    .build();

            return toDto(userInfoRepository.save(info));
        }

        // Update: only apply non-null values (do not overwrite with null)
        if (req.getFirstName() != null)
            info.setFirstName(req.getFirstName().trim());
        if (req.getLastName() != null)
            info.setLastName(req.getLastName().trim());
        if (req.getMiddleName() != null)
            info.setMiddleName(req.getMiddleName());
        if (req.getPreferredName() != null)
            info.setPreferredName(req.getPreferredName());

        if (req.getCountry() != null)
            info.setCountry(req.getCountry());
        if (req.getBirthDate() != null)
            info.setBirthDate(req.getBirthDate());
        if (req.getGender() != null)
            info.setGender(req.getGender());
        if (req.getProfileImageUrl() != null)
            info.setProfileImageUrl(req.getProfileImageUrl());

        return toDto(userInfoRepository.save(info));
    }

    // ──────────────────────────────────────────────
    // Profile photo (PostgreSQL bytea)
    // ──────────────────────────────────────────────

    private static final long MAX_PHOTO_SIZE = 2 * 1024 * 1024; // 2 MB

    /**
     * Upload profile photo — stores binary data directly in PostgreSQL bytea.
     * Max 2 MB, only image/* content types allowed.
     */
    @Transactional
    public void uploadProfilePhoto(MultipartFile file) {
        if (file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File is empty");
        }
        if (file.getSize() > MAX_PHOTO_SIZE) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "File too large — max 2 MB allowed");
        }
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Only image files are allowed (image/jpeg, image/png, etc.)");
        }

        User user = currentUserProvider.getCurrentUserEntity();
        UserInfo info = userInfoRepository.findByUser(user)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Create profile before uploading photo"));

        try {
            info.setProfileImageData(file.getBytes());
            info.setProfileImageType(contentType);
            userInfoRepository.save(info);
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "Failed to read uploaded file");
        }
    }

    /**
     * Returns profile photo bytes + content type.
     * @return map with "data" (byte[]) and "contentType" (String)
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getProfilePhoto() {
        User user = currentUserProvider.getCurrentUserEntity();
        UserInfo info = userInfoRepository.findByUser(user)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "User profile not found"));

        if (info.getProfileImageData() == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "No profile photo uploaded");
        }

        return Map.of(
                "data", info.getProfileImageData(),
                "contentType", info.getProfileImageType() != null
                        ? info.getProfileImageType() : "image/jpeg"
        );
    }

    /**
     * Delete profile photo — clears binary data from DB.
     */
    @Transactional
    public void deleteProfilePhoto() {
        User user = currentUserProvider.getCurrentUserEntity();
        UserInfo info = userInfoRepository.findByUser(user)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "User profile not found"));

        info.setProfileImageData(null);
        info.setProfileImageType(null);
        userInfoRepository.save(info);
    }

    private UserInfoResponseDTO toDto(UserInfo info) {
        return UserInfoResponseDTO.builder()
                .infoId(info.getInfoId())
                .userId(info.getUser().getUserId())
                .email(info.getUser().getEmail())
                .firstName(info.getFirstName())
                .middleName(info.getMiddleName())
                .lastName(info.getLastName())
                .preferredName(info.getPreferredName())
                .displayName(info.getDisplayName())
                .country(info.getCountry())
                .birthDate(info.getBirthDate())
                .gender(info.getGender())
                .profileImageUrl(info.getProfileImageUrl())
                .hasProfilePhoto(info.getProfileImageData() != null)
                .joinDate(info.getJoinDate())
                .build();
    }

    private boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
