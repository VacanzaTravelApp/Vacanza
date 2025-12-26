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

    /**
     * login sonrası ve app açılışında session restore için çağrılır.
     * firebase ID token Bearer olarak gönderilir.
     */
    @GetMapping("/login")
    public ResponseEntity<UserAuthenticationDTO> login(HttpServletRequest request) {
        return new ResponseEntity<>(authService.getMe(request), HttpStatus.OK);
    }

    @GetMapping("/me")
    public ResponseEntity<UserAuthenticationDTO> me(HttpServletRequest request) {
        return new ResponseEntity<>(authService.getMe(request), HttpStatus.OK);
    }
}