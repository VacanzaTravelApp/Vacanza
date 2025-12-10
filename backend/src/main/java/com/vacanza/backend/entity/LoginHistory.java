package com.vacanza.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "login_history")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginHistory {

    @Id
    @GeneratedValue
    @UuidGenerator
    @Column(name = "login_id", nullable = false, updatable = false)
    private UUID loginId;

    // FK: users.user_id (user tablosu ile iliskilendirme)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // user ne ile kaydoldu bilgisi (simdilik firebase)
    @Column(name = "login_provider", nullable = false, length = 50)
    private String loginProvider;

    @Column(name = "login_time", nullable = false)
    private Instant loginTime;

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    @PrePersist
    protected void onCreate() {
        if (this.loginTime == null) {
            this.loginTime = Instant.now();
        }
        if (this.loginProvider == null) {
            // su anlik firebase
            this.loginProvider = "firebase";
        }
    }
}
