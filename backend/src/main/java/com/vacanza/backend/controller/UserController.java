package com.vacanza.backend.controller;


import com.vacanza.backend.dto.request.UserLoginRequestDTO;
import com.vacanza.backend.dto.response.UserLoginResponseDTO;
import com.vacanza.backend.service.UserService;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@AllArgsConstructor
@RestController
@RequestMapping(path = "/user")
public class UserController {

    private final UserService userService;

    @GetMapping("/get-all-user")
    public ResponseEntity<List<UserLoginResponseDTO>> getAllUser() {
        List<UserLoginResponseDTO> response = userService.getAllUsers();
        return new ResponseEntity<>(response, HttpStatus.OK);
    }

    @GetMapping("/get-current-user")
    public ResponseEntity<UserLoginResponseDTO> getCurrentUser() {
        UserLoginResponseDTO response = userService.getCurrentUser();
        return new ResponseEntity<>(response, HttpStatus.OK);
    }

    @PostMapping("/add-new-user")
    public ResponseEntity<UserLoginResponseDTO> addNewUser(@RequestBody UserLoginRequestDTO request) {
        UserLoginResponseDTO response = userService.addNewUser(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }




}
