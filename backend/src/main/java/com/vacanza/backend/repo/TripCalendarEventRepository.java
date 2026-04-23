package com.vacanza.backend.repo;

import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.TripCalendarEvent;
import com.vacanza.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TripCalendarEventRepository extends JpaRepository<TripCalendarEvent, UUID> {

    List<TripCalendarEvent> findByUserAndEventDateBetweenOrderByEventDateAsc(
            User user, LocalDate startInclusive, LocalDate endInclusive);

    Optional<TripCalendarEvent> findByEventIdAndUser(UUID eventId, User user);

    boolean existsByUserAndAiRouteAndEventDate(User user, AiRoute aiRoute, LocalDate eventDate);

    List<TripCalendarEvent> findByUserAndAiRouteOrderByEventDateAsc(User user, AiRoute aiRoute);

    @Modifying(clearAutomatically = true)
    @Query("DELETE FROM TripCalendarEvent e WHERE e.user = :user AND e.aiRoute.routeId = :routeId")
    int deleteByUserAndRouteId(@Param("user") User user, @Param("routeId") UUID routeId);
}
