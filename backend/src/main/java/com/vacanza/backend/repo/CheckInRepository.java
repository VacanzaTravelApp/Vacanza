package com.vacanza.backend.repo;

import com.vacanza.backend.entity.CheckIn;
import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface CheckInRepository extends JpaRepository<CheckIn, UUID> {

    // kullanici ayni POI'ye tekrar check-in yapmasin diye kontrol
    boolean existsByUserAndPointOfInterest(User user, PointOfInterest poi);
}
