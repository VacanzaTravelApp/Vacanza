package com.vacanza.backend.service;

import com.vacanza.backend.dto.trip.CreateTripCalendarEventRequest;
import com.vacanza.backend.dto.trip.TripCalendarEventResponse;
import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.TripCalendarEvent;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.repo.TripCalendarEventRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TripCalendarService {

    private final TripCalendarEventRepository tripCalendarEventRepository;
    private final AiRouteService aiRouteService;

    @Transactional(readOnly = true)
    public List<TripCalendarEventResponse> listForMonth(User user, int year, int month) {
        LocalDate start = LocalDate.of(year, month, 1);
        LocalDate end = start.withDayOfMonth(start.lengthOfMonth());
        return tripCalendarEventRepository
                .findByUserAndEventDateBetweenOrderByEventDateAsc(user, start, end)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    /**
     * Adds the route to consecutive calendar days starting at {@code eventDate}:
     * one row per itinerary day (Day 1, Day 2, …) when totalDays &gt; 1.
     */
    @Transactional
    public List<TripCalendarEventResponse> create(User user, CreateTripCalendarEventRequest request) {
        AiRoute route = aiRouteService
                .getRoute(request.routeId(), user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Route not found"));
        int totalDays = Math.max(1, route.getTotalDays());
        LocalDate start = request.eventDate();
        for (int day = 1; day <= totalDays; day++) {
            LocalDate d = start.plusDays(day - 1L);
            if (tripCalendarEventRepository.existsByUserAndAiRouteAndEventDate(user, route, d)) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "This route is already on your calendar on " + d + " (day " + day + ").");
            }
        }
        List<TripCalendarEventResponse> out = new ArrayList<>();
        for (int day = 1; day <= totalDays; day++) {
            LocalDate d = start.plusDays(day - 1L);
            TripCalendarEvent entity = TripCalendarEvent.builder()
                    .user(user)
                    .aiRoute(route)
                    .eventDate(d)
                    .itineraryDay(day)
                    .build();
            TripCalendarEvent saved = tripCalendarEventRepository.save(entity);
            out.add(toResponse(saved));
        }
        return out;
    }

    @Transactional
    public void delete(User user, UUID eventId) {
        TripCalendarEvent ev = tripCalendarEventRepository
                .findByEventIdAndUser(eventId, user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Event not found"));
        tripCalendarEventRepository.delete(ev);
    }

    /**
     * Removes every calendar row for this route (all itinerary days).
     */
    @Transactional
    public void deleteAllForRoute(User user, UUID routeId) {
        if (aiRouteService.getRoute(routeId, user).isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Route not found");
        }
        tripCalendarEventRepository.deleteByUserAndRouteId(user, routeId);
    }

    private TripCalendarEventResponse toResponse(TripCalendarEvent e) {
        AiRoute r = e.getAiRoute();
        int iday = e.getItineraryDay() == null ? 1 : e.getItineraryDay();
        return new TripCalendarEventResponse(
                e.getEventId(),
                r.getRouteId(),
                r.getTitle(),
                r.getDestination(),
                e.getEventDate(),
                r.getTotalDays(),
                iday);
    }
}
