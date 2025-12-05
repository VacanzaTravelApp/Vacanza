package com.vacanza.backend.entity;

import com.vacanza.backend.entity.enums.Gender;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "user_info")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserInfo {

    @Id
    @GeneratedValue
    @UuidGenerator
    @Column(name = "info_id", nullable = false, updatable = false)
    private UUID infoId;

    //users table'i ile 1-1 iliski (SRS dokumanina gore)
    //bir userin yalnizca 1 profil ekrani olabilir
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(
            name = "user_id",
            referencedColumnName = "user_id",
            nullable = false,
            unique = true
    )
    private User user;

    @Column(name = "first_name", nullable = false, length = 80)
    private String firstName;

    @Column(name = "last_name", nullable = false, length = 80)
    private String lastName;

    @Column(name = "country", length = 80)
    private String country;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "gender", length = 30)
    private Gender gender;

    /*
    buna su anlik gerek yok ama 2. dil geldiginde gerek olabilir
    @Column(name = "preferred_language", length = 10)
    private String preferredLanguage;
     */

    @Column(name = "profile_image")
    private String profileImage;

    @Column(name = "join_date", nullable = false, updatable = false)
    private Instant joinDate;

    @PrePersist
    protected void onCreate() {
        this.joinDate = Instant.now();
    }
}
