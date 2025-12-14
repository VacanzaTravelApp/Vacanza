package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.UserRegisterRequestDTO;
import com.vacanza.backend.dto.response.UserAuthenticationDTO;
import com.vacanza.backend.dto.response.UserRegisterResponseDTO;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserInfo;
import com.vacanza.backend.repo.UserInfoRepository;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.impl.AuthImpl;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.Instant;

@Service
public class AuthService implements AuthImpl {

    private final CurrentUserProvider currentUserProvider;
    private final UserInfoRepository userInfoRepository;

    public AuthService(CurrentUserProvider currentUserProvider,
                       UserInfoRepository userInfoRepository) {
        this.currentUserProvider = currentUserProvider;
        this.userInfoRepository = userInfoRepository;
    }

    @Override
    public UserAuthenticationDTO getMe(HttpServletRequest request) {
        User user = currentUserProvider.getCurrentUserEntity();

        boolean profileCompleted = userInfoRepository.existsByUser(user);

        Object verifiedAttr = request.getAttribute("firebaseEmailVerified");
        boolean verified = verifiedAttr instanceof Boolean && (Boolean) verifiedAttr;

        return UserAuthenticationDTO.builder()
                .userId(user.getUserId())
                .firebaseUid(user.getFirebaseUid())
                .email(user.getEmail())
                .role(user.getRole().name())
                .verified(verified)
                .profileCompleted(profileCompleted)
                .build();
    }

    @Override
    public UserRegisterResponseDTO onboard(UserRegisterRequestDTO req) {
        User user = currentUserProvider.getCurrentUserEntity();

        UserInfo info = userInfoRepository.findByUser(user).orElse(null);

        if (info == null) {
            if (!StringUtils.hasText(req.getFirstName()) || !StringUtils.hasText(req.getLastName())) {
                return UserRegisterResponseDTO.builder()
                        .success(false)
                        .message("firstName and lastName are required")
                        .userId(user.getUserId())
                        .build();
            }

            info = UserInfo.builder()
                    .user(user)
                    .firstName(req.getFirstName())
                    .middleName(req.getMiddleName())
                    .lastName(req.getLastName())
                    .preferredName(req.getPreferredName())
                    .joinDate(Instant.now())
                    .build();
        } else {
            if (StringUtils.hasText(req.getFirstName())) info.setFirstName(req.getFirstName());
            info.setMiddleName(req.getMiddleName());
            if (StringUtils.hasText(req.getLastName())) info.setLastName(req.getLastName());
            info.setPreferredName(req.getPreferredName());
        }

        userInfoRepository.save(info);

        return UserRegisterResponseDTO.builder()
                .success(true)
                .message("Profile saved")
                .userId(user.getUserId())
                .build();
    }
}
