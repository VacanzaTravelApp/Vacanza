package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.UserLoginHistoryRequestDTO;
import com.vacanza.backend.dto.response.UserLoginHistoryResponseDTO;
import com.vacanza.backend.entity.LoginHistory;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.exceptions.enums.UserLoginHistoryExceptionEnum;
import com.vacanza.backend.repo.UserLoginHistoryRepository;
import com.vacanza.backend.repo.UserRepository;
import com.vacanza.backend.service.impl.UserLoginHistoryImpl;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class UserLoginHistoryService implements UserLoginHistoryImpl {

    private final UserLoginHistoryRepository userLoginHistoryRepository;
    private final UserRepository userRepository;

    public UserLoginHistoryService(UserLoginHistoryRepository userLoginHistoryRepository, UserRepository userRepository) {
        this.userLoginHistoryRepository = userLoginHistoryRepository;
        this.userRepository = userRepository;
    }

    public List<UserLoginHistoryResponseDTO> getAllLoginHistories() {
        return userLoginHistoryRepository.findAll()
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

    @Override
    public List<UserLoginHistoryResponseDTO> getMyLoginHistories() {
        return List.of();
    }

    @Transactional(readOnly = true)
    public List<UserLoginHistoryResponseDTO> getAllLoginHistoriesByUserId(UserLoginHistoryRequestDTO request) {
        return userLoginHistoryRepository.findByUserUserId(request.getUserId())
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
                .orElseThrow(() -> new RuntimeException(UserLoginHistoryExceptionEnum.NullUserId.getExplanation()));

        if (request.getIpAddress() == null) {
            throw new RuntimeException(UserLoginHistoryExceptionEnum.NullIP.getExplanation());
        } else {

            LoginHistory loginHistory = new LoginHistory();
            loginHistory.setUser(user);
            loginHistory.setLoginProvider("Firebase");
            loginHistory.setIpAddress(request.getIpAddress());
            loginHistory.setLoginTime(Instant.now());

            LoginHistory savedLoginHistory = userLoginHistoryRepository.save(loginHistory);

        }
    }


}
