package com.vacanza.backend.controller;

import com.vacanza.backend.dto.request.UserInfoRequestDTO;
import com.vacanza.backend.dto.response.UserInfoResponseDTO;
import com.vacanza.backend.dto.response.UserRegisterResponseDTO;
import com.vacanza.backend.service.UserInfoService;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;
import java.util.UUID;

@RestController
@AllArgsConstructor
public class UserInfoController {

    private final UserInfoService userInfoService;

    /**
     * register sonrası çağrılır (Firebase register + token alındıktan sonra)
     * profil bilgilerini DB'ye upsert eder (create if missing, else update).
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
     * profil ekranında data çekmek için
     */
    @GetMapping("/users/me/profile")
    public ResponseEntity<UserInfoResponseDTO> getProfile() {
        return new ResponseEntity<>(userInfoService.getUserInfo(), HttpStatus.OK);
    }

    /**
     * profil güncellemek için (standart HTTP method: PUT)
     */
    @PutMapping("/users/me/profile")
    public ResponseEntity<UserInfoResponseDTO> updateProfile(@RequestBody UserInfoRequestDTO request) {
        return new ResponseEntity<>(userInfoService.updateUserInfo(request), HttpStatus.OK);
    }

    // ────────────────────────────────────────────────
    // Profile photo (PostgreSQL bytea)
    // ────────────────────────────────────────────────

    /**
     * Profil fotoğrafı yükle (multipart/form-data).
     * Max 2 MB, sadece image/* dosyalar kabul edilir.
     */
    @PostMapping(value = "/users/me/profile/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, String>> uploadProfilePhoto(
            @RequestParam("file") MultipartFile file) {

        userInfoService.uploadProfilePhoto(file);
        return ResponseEntity.ok(Map.of("message", "Profile photo uploaded successfully"));
    }

    /**
     * Profil fotoğrafını binary olarak döndürür.
     * Response Content-Type: image/jpeg, image/png vb.
     */
    @GetMapping("/users/me/profile/photo")
    public ResponseEntity<byte[]> getProfilePhoto() {
        Map<String, Object> photo = userInfoService.getProfilePhoto();
        byte[] data = (byte[]) photo.get("data");
        String contentType = (String) photo.get("contentType");

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_TYPE, contentType)
                .header(HttpHeaders.CACHE_CONTROL, "max-age=86400")
                .body(data);
    }

    /**
     * Profil fotoğrafını sil.
     */
    @DeleteMapping("/users/me/profile/photo")
    public ResponseEntity<Map<String, String>> deleteProfilePhoto() {
        userInfoService.deleteProfilePhoto();
        return ResponseEntity.ok(Map.of("message", "Profile photo deleted"));
    }

    // eski endpointler

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