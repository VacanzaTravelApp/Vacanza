package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.UserLoginHistoryRequestDTO;
import com.vacanza.backend.dto.response.UserLoginHistoryResponseDTO;
import com.vacanza.backend.dto.response.UserLoginResponseDTO;
import com.vacanza.backend.entity.LoginHistory;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.exceptions.enums.LoginHistoryExceptionEnum;
import com.vacanza.backend.repo.LoginHistoryRepository;
import com.vacanza.backend.repo.UserRepository;
import com.vacanza.backend.service.impl.LoginHistoryImpl;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class LoginHistoryService implements LoginHistoryImpl {

    private final LoginHistoryRepository loginHistoryRepository;
    private final UserRepository userRepository;

    public LoginHistoryService(LoginHistoryRepository loginHistoryRepository, UserRepository userRepository) {
        this.loginHistoryRepository = loginHistoryRepository;
        this.userRepository = userRepository;
    }

    public List<UserLoginHistoryResponseDTO> getAllLoginHistories() {
        return loginHistoryRepository.findAll()
                .stream()
                .map(item -> UserLoginHistoryResponseDTO.builder()
                        .loginId(item.getLoginId())
                        .userId(item.getUser().getUserId())
                        .loginProvider(item.getLoginProvider())
                        .loginTime(item.getLoginTime())
                        .ipAddress(item.getIpAddress())
                        .build())
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<UserLoginHistoryResponseDTO> getAllLoginHistoriesByUserId(UUID userId) {
        return loginHistoryRepository.findByUserUserId(userId)
                .stream()
                .map(item -> UserLoginHistoryResponseDTO.builder()
                        .loginId(item.getLoginId())
                        .userId(item.getUser().getUserId())
                        .loginProvider(item.getLoginProvider())
                        .loginTime(item.getLoginTime())
                        .ipAddress(item.getIpAddress())
                        .build())
                .collect(Collectors.toList());
    }


    public void addNewLoginHistory(UserLoginHistoryRequestDTO request) {

        User user = userRepository.findByUserId(request.getUserId())
                .orElseThrow(() -> new RuntimeException(LoginHistoryExceptionEnum.NullUserId.getExplanation()));

        if (request.getIpAddress() == null) {
            throw new RuntimeException(LoginHistoryExceptionEnum.NullIP.getExplanation());
        } else {

            LoginHistory loginHistory = new LoginHistory();
            loginHistory.setUser(user);
            loginHistory.setLoginProvider("Firebase");
            loginHistory.setIpAddress(request.getIpAddress());
            loginHistory.setLoginTime(Instant.now());

            LoginHistory savedLoginHistory = loginHistoryRepository.save(loginHistory);

        }
    }


}
