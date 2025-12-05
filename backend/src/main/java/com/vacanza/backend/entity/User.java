package com.vacanza.backend.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.vacanza.backend.entity.enums.Role;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(
        name = "users",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_users_email", columnNames = "email"),
                @UniqueConstraint(name = "uk_users_firebase_uid", columnNames = "firebase_uid")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder

public class User {

    @Id
    @GeneratedValue
    @UuidGenerator
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    @Column(name = "firebase_uid", nullable = false, unique = true, length = 128)
    private String firebaseUid;

    @Column(name = "email", nullable = false, unique = true, length = 120)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false, length = 20)
    private Role role;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    //relationship alani (kullanici birden fazla historye sahip olabilir
    //json serialization loopu engelliyor
    //kullanici silinirse ona bagli historyler de silinecek (cascase ile)
    @OneToMany(mappedBy = "user", fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    @JsonIgnore
    private List<LoginHistory> loginHistoryList = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        this.createdAt = Instant.now();
        if (this.role == null) {
            this.role = Role.USER;
        }
    }
}
