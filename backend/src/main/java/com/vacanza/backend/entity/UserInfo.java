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

    @OneToOne
    @JoinColumn(name = "user_id", referencedColumnName = "user_id", nullable = false)
    private User user;

    //first ve last name olarak ayirdim full name yerine
    //maintainability daha kolay
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
    bu srs'te yaziyodu ama olmasina su anlik gerek yok, sadece ingilizceyiz
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

    /*
    first ve last name olarak ayirdim, full name gerekirse method

    public String getFullName() {
        return firstName + " " + lastName;
    }
    */
}
