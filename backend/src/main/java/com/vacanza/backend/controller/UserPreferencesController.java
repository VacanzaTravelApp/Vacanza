package com.vacanza.backend.controller;

import com.vacanza.backend.dto.request.UserPreferencesRequestDTO;
import com.vacanza.backend.dto.response.UserPreferencesResponseDTO;
import com.vacanza.backend.service.UserPreferencesService;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/user/preferences")
@AllArgsConstructor
public class UserPreferencesController {

    private final UserPreferencesService preferencesService;

    /**
     * Kullanıcının mevcut tercihlerini getirir.
     */
    @GetMapping
    public ResponseEntity<UserPreferencesResponseDTO> getPreferences() {
        return new ResponseEntity<>(preferencesService.getPreferences(), HttpStatus.OK);
    }

    /**
     * Tercihleri oluşturur veya günceller (upsert).
     * Sadece gönderilen alanlar güncellenir, null olanlar atlanır.
     */
    @PutMapping
    public ResponseEntity<UserPreferencesResponseDTO> updatePreferences(
            @RequestBody UserPreferencesRequestDTO request) {
        return new ResponseEntity<>(preferencesService.updatePreferences(request), HttpStatus.OK);
    }
}
