package com.vacanza.backend.controller;

import com.vacanza.backend.dto.request.UserInfoRequestDTO;
import com.vacanza.backend.dto.response.UserInfoResponseDTO;
import com.vacanza.backend.dto.response.UserRegisterResponseDTO;
import com.vacanza.backend.service.UserInfoService;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@AllArgsConstructor
public class UserInfoController {

    private final UserInfoService userInfoService;

    /**
        register sonrası çağrılır (Firebase register + token alındıktan sonra)
        profil bilgilerini DB'ye upsert eder (create if missing, else update).
     */
    @PostMapping("/auth/register")
    public ResponseEntity<UserRegisterResponseDTO> register(
            @RequestBody UserInfoRequestDTO request) {

        UUID userId = userInfoService.updateUserInfo(request).getUserId();

        UserRegisterResponseDTO response = UserRegisterResponseDTO.builder()
                .success(true)
                .message("User registered successfully")
                .userId(userId)
                .build();

        return new ResponseEntity<>(response, HttpStatus.OK);
    }

    /**
        profil ekranında data çekmek için
     */
    @GetMapping("/user/profile")
    public ResponseEntity<UserInfoResponseDTO> getProfile() {
        return new ResponseEntity<>(userInfoService.getUserInfo(), HttpStatus.OK);
    }

    /**
        profil güncellemek için (standart HTTP method: PUT)
     */
    @PutMapping("/user/profile")
    public ResponseEntity<UserInfoResponseDTO> updateProfile(@RequestBody UserInfoRequestDTO request) {
        return new ResponseEntity<>(userInfoService.updateUserInfo(request), HttpStatus.OK);
    }

    //eski endpointler

    @RestController
    @RequestMapping(path = "/user-info")
    @AllArgsConstructor
    static class LegacyUserInfoController {

        private final UserInfoService userInfoService;

        @GetMapping("/get-profile")
        public ResponseEntity<UserInfoResponseDTO> getUserInfo() {
            return new ResponseEntity<>(userInfoService.getUserInfo(), HttpStatus.OK);
        }

        @PostMapping("/update-profile")
        public ResponseEntity<UserInfoResponseDTO> updateUserInfo(@RequestBody UserInfoRequestDTO request) {
            return new ResponseEntity<>(userInfoService.updateUserInfo(request), HttpStatus.OK);
        }
    }
}