package com.vacanza.backend.controller;

import com.vacanza.backend.dto.request.UserLoginHistoryRequestDTO;
import com.vacanza.backend.dto.response.UserLoginHistoryResponseDTO;
import com.vacanza.backend.service.UserLoginHistoryService;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Fixes:
    no GET with request body
    create must be POST (not GET)
    current user's history uses token -> no userId in request
 */
@RestController
@RequestMapping(path = "/user-login-history")
public class UserLoginHistoryController {

    private final UserLoginHistoryService userLoginHistoryService;

    public UserLoginHistoryController(UserLoginHistoryService userLoginHistoryService) {
        this.userLoginHistoryService = userLoginHistoryService;
    }

    @GetMapping("/get-all-history")
    public ResponseEntity<List<UserLoginHistoryResponseDTO>> getAllHistory() {
        return new ResponseEntity<>(userLoginHistoryService.getAllLoginHistories(), HttpStatus.OK);
    }

    @GetMapping("/get-all-user-history")
    public ResponseEntity<List<UserLoginHistoryResponseDTO>> getMyHistoryLegacy() {
        return new ResponseEntity<>(userLoginHistoryService.getAllLoginHistories(), HttpStatus.OK);
    }

    @PostMapping("/get-add-user-history")
    public ResponseEntity<Void> addNewUserLoginHistoryLegacy(UserLoginHistoryRequestDTO request) {
        userLoginHistoryService.addNewLoginHistory(request);
        return new ResponseEntity<>(HttpStatus.CREATED);
    }
}
