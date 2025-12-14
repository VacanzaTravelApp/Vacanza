package com.vacanza.backend.controller;

import com.vacanza.backend.dto.request.UserInfoRequestDTO;
import com.vacanza.backend.dto.response.UserInfoResponseDTO;
import com.vacanza.backend.service.UserInfoService;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Profile endpoints:
 * - GET  /user-info/get-profile
 * - POST /user-info/update-profile  (upsert: create if missing, else update)
 * <p>
 * Register screen on Flutter/React:
 * After Firebase register + token, call /auth/me,
 * if profileCompleted=false -> call /userInfo/update-profile
 */
@RestController
@RequestMapping(path = "/user-info")
@AllArgsConstructor
public class UserInfoController {

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
