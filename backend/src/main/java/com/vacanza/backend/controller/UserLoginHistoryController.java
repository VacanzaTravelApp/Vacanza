package com.vacanza.backend.controller;

import com.vacanza.backend.dto.request.UserLoginHistoryRequestDTO;
import com.vacanza.backend.dto.response.UserLoginHistoryResponseDTO;
import com.vacanza.backend.service.UserLoginHistoryService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping(path = "/user-login-history")
public class UserLoginHistoryController {

    private final UserLoginHistoryService userLoginHistoryService;

    public UserLoginHistoryController(UserLoginHistoryService userLoginHistoryService) {
        this.userLoginHistoryService = userLoginHistoryService;
    }

    // Get all history
    @GetMapping("/get-all-history")
    public ResponseEntity<List<UserLoginHistoryResponseDTO>> getAllHistory() {
        return new ResponseEntity<>(userLoginHistoryService.getAllLoginHistories(), HttpStatus.OK);
    }

    // Get all history of a user, Parameter: user id
    @GetMapping("/get-all-user-history")
    public ResponseEntity<List<UserLoginHistoryResponseDTO>> getUserLoginHistory(@RequestBody UserLoginHistoryRequestDTO userLoginHistoryRequestDTO) {
        return new ResponseEntity<>(userLoginHistoryService.getAllLoginHistoriesByUserId(userLoginHistoryRequestDTO), HttpStatus.OK);
    }

    // Get all history of a user, Parameter: user id
    @GetMapping("/get-add-user-history")
    public void addNewUserLoginHistory(@RequestBody UserLoginHistoryRequestDTO userLoginHistoryRequestDTO) {
        userLoginHistoryService.addNewLoginHistory(userLoginHistoryRequestDTO);
    }
}
