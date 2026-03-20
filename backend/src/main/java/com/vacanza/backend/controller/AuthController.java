package com.vacanza.backend.controller;

import com.vacanza.backend.dto.response.UserAuthenticationDTO;
import com.vacanza.backend.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

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

    /**
     * Logout endpoint.
     * Firebase token lifecycle frontend tarafından yönetilir.
     * Bu endpoint login history kaydı oluşturur ve frontend API contract'ı için
     * mevcuttur.
     */
    @PostMapping("/logout")
    public ResponseEntity<Map<String, Object>> logout(HttpServletRequest request) {
        authService.logout(request);
        return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Logged out successfully"));
    }
}