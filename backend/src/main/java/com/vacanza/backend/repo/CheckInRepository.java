package com.vacanza.backend.repo;

import com.vacanza.backend.entity.CheckIn;
import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface CheckInRepository extends JpaRepository<CheckIn, UUID> {

    // kullanici ayni POI'ye tekrar check-in yapmasin diye kontrol
    boolean existsByUserAndPointOfInterest(User user, PointOfInterest poi);

    // Gamification: total check-in count for a user
    long countByUser(User user);

    // Gamification: check-in count for specific POI categories
    @Query("SELECT COUNT(c) FROM CheckIn c WHERE c.user = :user AND c.pointOfInterest.category IN :categories")
    long countByUserAndCategories(@Param("user") User user, @Param("categories") List<String> categories);

    // Gamification: distinct category count for a user (Explorer badge)
    @Query("SELECT COUNT(DISTINCT c.pointOfInterest.category) FROM CheckIn c WHERE c.user = :user")
    long countDistinctCategoriesByUser(@Param("user") User user);
}
