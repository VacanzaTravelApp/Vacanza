package com.vacanza.backend.service;


import com.vacanza.backend.entity.User;
import com.vacanza.backend.repo.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository userRepository;


    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User findByFirebaseUid(String firebaseUid) {
        return userRepository.findByFirebaseUid(firebaseUid).orElseThrow(() -> new RuntimeException("new ResourceNotFoundException(\"User not found with UID: \" + firebaseUid"));
    }

    public User getCurrentUser() {
        String uid = (String) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return findByFirebaseUid(uid);
    }
}
