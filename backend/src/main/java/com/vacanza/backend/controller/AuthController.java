package com.vacanza.backend.controller;

import com.vacanza.backend.dto.response.UserAuthenticationDTO;
import com.vacanza.backend.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
@AllArgsConstructor
public class AuthController {

    private final AuthService authService;

    @GetMapping("/me")
    public ResponseEntity<UserAuthenticationDTO> me(HttpServletRequest request) {
        return new ResponseEntity<>(authService.getMe(request), HttpStatus.OK);
    }

    /*
    @PostMapping("/onboard")
    public ResponseEntity<UserRegisterResponseDTO> onboard(@RequestBody UserRegisterRequestDTO req) {
        return new ResponseEntity<>(authService.onboard(req), HttpStatus.OK);
    }
     */
}
