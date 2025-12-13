package com.vacanza.backend.controller;


import com.vacanza.backend.dto.request.UserInfoRequestDTO;
import com.vacanza.backend.dto.response.UserInfoResponseDTO;
import com.vacanza.backend.service.UserInfoService;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping(path = "/userInfo")
@AllArgsConstructor
public class UserInfoController {

    private final UserInfoService userInfoService;

    @GetMapping("/get-profile")
    public ResponseEntity<UserInfoResponseDTO> getUserInfo(){
        UserInfoResponseDTO response = userInfoService.getUserInfo();
        return new ResponseEntity<>(response, HttpStatus.OK);
    }

    @PostMapping("/update-profile")
    public ResponseEntity<UserInfoResponseDTO> updateUserInfo(@RequestBody UserInfoRequestDTO request) {
        UserInfoResponseDTO response = userInfoService.updateUserInfo(request);
        return new ResponseEntity<>(response, HttpStatus.OK);
    }

}
