package com.vacanza.backend.dev;

import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.enums.Role;
import com.vacanza.backend.repo.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/dev/admin")
@Profile("dev")
@RequiredArgsConstructor
@Slf4j
public class DevAdminController {

    private final UserRepository userRepository;

    @GetMapping("/promote")
    public ResponseEntity<Map<String, Object>> promoteToAdmin(@RequestParam String email) {
        Optional<User> userOptional = userRepository.findByEmail(email);
        
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            user.setRole(Role.ADMIN);
            userRepository.save(user);
            
            log.info("[DEV] User {} promoted to ADMIN", email);
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "User " + email + " promoted to ADMIN successfully",
                "email", email,
                "role", "ADMIN"
            ));
        } else {
            return ResponseEntity.status(404).body(Map.of(
                "success", false,
                "message", "User not found with email: " + email
            ));
        }
    }
}
