package com.vacanza.backend.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.dto.request.EventSearchRequestDTO;
import com.vacanza.backend.dto.response.EventDTO;
import com.vacanza.backend.dto.response.EventRecommendationResponse;
import com.vacanza.backend.dto.response.RecommendedEvent;
import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserPreferences;
import com.vacanza.backend.dto.weather.DailyWeatherSummary;
import com.vacanza.backend.dto.weather.DayPartWeatherDay;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.integration.ai.AiServiceClient;
import com.vacanza.backend.repo.UserPreferencesRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZonedDateTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Orchestrates event recommendations for a saved AI route: preferences → Ticketmaster search →
 * virtual filter → optional AI ranking.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EventRecommendationService {

    private static final String FALLBACK_MESSAGE_TR = "Rotanız için bulunan etkinlikler:";

    private final AiRouteService aiRouteService;
    private final UserPreferencesRepository userPreferencesRepository;
    private final UserPreferenceAiService userPreferenceAiService;
    private final EventPreferenceMapper eventPreferenceMapper;
    private final EventService eventService;
    private final AiServiceClient aiServiceClient;
    private final ObjectMapper objectMapper;

    @Transactional(readOnly = true)
    public EventRecommendationResponse getRecommendations(UUID routeId, User user, Integer tripDay) {
        AiRoute route = aiRouteService.getRoute(routeId, user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Route not found"));

        AiChatDto.RouteData routeData = parseRouteJson(route.getRouteJson());

        UserPreferences structured = userPreferencesRepository.findByUser(user).orElse(null);
        List<AiChatDto.ExtractedPreference> aiPrefs = userPreferenceAiService.getExistingPreferences(user);
        List<String> categories = eventPreferenceMapper.mapToTicketmasterCategoriesFromExtracted(structured, aiPrefs);

        String rawDestination = firstNonBlank(
                routeData != null ? routeData.getDestination() : null,
                route.getDestination());
        String city = parseCityName(rawDestination);
        if (city.isBlank()) {
            log.warn("No destination city for route {}", routeId);
            return emptyResponse();
        }

        int totalDays = resolveTotalDays(routeData, route);
        LocalDate tripStart = resolveTripStartLocalDate(routeData, route);

        Integer normalizedDay = normalizeTripDay(tripDay, totalDays);

        EventSearchRequestDTO request = new EventSearchRequestDTO();
        request.setCity(city);
        if (normalizedDay != null) {
            LocalDate dayDate = tripStart.plusDays(normalizedDay - 1);
            request.setStartDate(dayDate);
            request.setEndDate(dayDate);
        } else {
            request.setStartDate(tripStart);
            request.setEndDate(computeEndDate(tripStart, totalDays));
        }
        String categoryParam = categories.isEmpty() ? null : String.join(", ", categories);
        request.setCategory(categoryParam);
        request.setSize(20);

        List<EventDTO> found;
        try {
            found = eventService.searchEvents(request);
        } catch (Exception e) {
            log.warn("Ticketmaster event search failed for route {}: {}", routeId, e.getMessage());
            return emptyResponse();
        }

        List<EventDTO> filtered = found.stream()
                .filter(e -> e.getIsVirtual() == null || !Boolean.TRUE.equals(e.getIsVirtual()))
                .collect(Collectors.toList());

        if (normalizedDay != null) {
            LocalDate target = tripStart.plusDays(normalizedDay - 1);
            filtered = filtered.stream()
                    .filter(e -> eventStartsOnLocalDate(e, target))
                    .collect(Collectors.toList());
        }

        int totalFound = filtered.size();
        if (totalFound == 0) {
            return EventRecommendationResponse.builder()
                    .message(null)
                    .events(List.of())
                    .totalFound(0)
                    .hasRecommendations(false)
                    .build();
        }

        AiChatDto.EventRecommendAiRequest aiRequest = buildEventRecommendRequest(
                routeData, rawDestination, totalDays, tripStart, structured, aiPrefs, filtered);
        Optional<AiChatDto.EventRecommendAiResponse> aiRanked =
                aiServiceClient.recommendEventsForRoute(user.getUserId(), aiRequest);

        if (aiRanked.isPresent()
                && aiRanked.get().getRecommendedEvents() != null
                && !aiRanked.get().getRecommendedEvents().isEmpty()) {
            List<RecommendedEvent> ranked = buildFromAiRecommendResponse(filtered, aiRanked.get());
            if (!ranked.isEmpty()) {
                String message = aiRanked.get().getMessage();
                if (message == null || message.isBlank()) {
                    message = FALLBACK_MESSAGE_TR;
                }
                return EventRecommendationResponse.builder()
                        .message(message)
                        .events(ranked)
                        .totalFound(totalFound)
                        .hasRecommendations(true)
                        .build();
            }
        }

        List<RecommendedEvent> sorted = sortByStartTime(filtered).stream()
                .map(e -> toRecommended(e, null))
                .collect(Collectors.toList());
        return EventRecommendationResponse.builder()
                .message(FALLBACK_MESSAGE_TR)
                .events(sorted)
                .totalFound(totalFound)
                .hasRecommendations(!sorted.isEmpty())
                .build();
    }

    private static EventRecommendationResponse emptyResponse() {
        return EventRecommendationResponse.builder()
                .message(null)
                .events(List.of())
                .totalFound(0)
                .hasRecommendations(false)
                .build();
    }

    private AiChatDto.RouteData parseRouteJson(String routeJson) {
        if (routeJson == null || routeJson.isBlank()) {
            return null;
        }
        try {
            return objectMapper.readValue(routeJson, AiChatDto.RouteData.class);
        } catch (JsonProcessingException e) {
            log.warn("Failed to parse route JSON: {}", e.getMessage());
            return null;
        }
    }

    private static int resolveTotalDays(AiChatDto.RouteData routeData, AiRoute route) {
        if (routeData != null && routeData.getTotalDays() > 0) {
            return routeData.getTotalDays();
        }
        return Math.max(route.getTotalDays(), 1);
    }

    /**
     * First calendar day of the trip: from embedded weather (aligned with itinerary days), else route creation date.
     */
    static LocalDate resolveTripStartLocalDate(AiChatDto.RouteData routeData, AiRoute route) {
        Optional<LocalDate> fromWeather = firstWeatherDate(routeData);
        return fromWeather.orElseGet(() -> route.getGeneratedAt().toLocalDate());
    }

    private static Optional<LocalDate> firstWeatherDate(AiChatDto.RouteData routeData) {
        if (routeData == null) {
            return Optional.empty();
        }
        List<DailyWeatherSummary> daily = routeData.getWeatherForecast();
        if (daily != null && !daily.isEmpty()) {
            LocalDate d = daily.get(0).date();
            if (d != null) {
                return Optional.of(d);
            }
        }
        List<DayPartWeatherDay> parts = routeData.getWeatherDayParts();
        if (parts != null && !parts.isEmpty()) {
            LocalDate d = parts.get(0).date();
            if (d != null) {
                return Optional.of(d);
            }
        }
        return Optional.empty();
    }

    /** @return 1-based day index within the trip, or null to search the whole trip window */
    private static Integer normalizeTripDay(Integer tripDay, int totalDays) {
        if (tripDay == null) {
            return null;
        }
        int d = tripDay;
        if (d < 1 || d > totalDays) {
            return null;
        }
        return d;
    }

    private static boolean eventStartsOnLocalDate(EventDTO e, LocalDate target) {
        if (e == null || target == null) {
            return false;
        }
        LocalDate parsed = parseEventStartLocalDate(e.getStartTime());
        if (parsed == null) {
            return true;
        }
        return parsed.equals(target);
    }

    private static LocalDate parseEventStartLocalDate(String startTime) {
        if (startTime == null || startTime.isBlank()) {
            return null;
        }
        String s = startTime.trim();
        try {
            return LocalDate.parse(s.length() >= 10 ? s.substring(0, 10) : s);
        } catch (DateTimeParseException ignored) {
            /* fall through */
        }
        try {
            return OffsetDateTime.parse(s).toLocalDate();
        } catch (DateTimeParseException ignored) {
            /* fall through */
        }
        try {
            return ZonedDateTime.parse(s).toLocalDate();
        } catch (DateTimeParseException ignored) {
            return null;
        }
    }

    private static LocalDate computeEndDate(LocalDate startDate, int totalDays) {
        if (totalDays <= 1) {
            return startDate;
        }
        return startDate.plusDays(totalDays - 1);
    }

    private static String firstNonBlank(String a, String b) {
        if (a != null && !a.isBlank()) {
            return a.trim();
        }
        if (b != null && !b.isBlank()) {
            return b.trim();
        }
        return "";
    }

    /**
     * "Istanbul, Turkey" → "Istanbul"
     */
    static String parseCityName(String destination) {
        if (destination == null || destination.isBlank()) {
            return "";
        }
        String trimmed = destination.trim();
        int comma = trimmed.indexOf(',');
        if (comma > 0) {
            return trimmed.substring(0, comma).trim();
        }
        return trimmed;
    }

    private static AiChatDto.EventRecommendAiRequest buildEventRecommendRequest(
            AiChatDto.RouteData routeData,
            String rawDestination,
            int totalDays,
            LocalDate tripStart,
            UserPreferences structured,
            List<AiChatDto.ExtractedPreference> aiPrefs,
            List<EventDTO> events) {
        AiChatDto.RouteSummaryForRecommend rs = new AiChatDto.RouteSummaryForRecommend();
        rs.setDestination(rawDestination != null ? rawDestination : "");
        rs.setTotalDays(totalDays);
        rs.setStartDate(tripStart.toString());

        List<AiChatDto.DaySummaryAi> daySummaries = new ArrayList<>();
        if (routeData != null && routeData.getDays() != null) {
            for (AiChatDto.DayPlan day : routeData.getDays()) {
                List<String> cats = new ArrayList<>();
                if (day.getWaypoints() != null) {
                    for (AiChatDto.RouteWaypoint w : day.getWaypoints()) {
                        if (w.getCategory() != null && !w.getCategory().isBlank()) {
                            cats.add(w.getCategory());
                        }
                    }
                }
                AiChatDto.DaySummaryAi ds = new AiChatDto.DaySummaryAi();
                ds.setDay(day.getDay());
                ds.setTitle(day.getTitle() != null ? day.getTitle() : "");
                ds.setCategories(cats);
                daySummaries.add(ds);
            }
        }
        rs.setDaySummaries(daySummaries);

        AiChatDto.UserPreferenceSummaryAi up = new AiChatDto.UserPreferenceSummaryAi();
        if (structured != null) {
            up.setTravelStyle(structured.getTravelStyle() != null ? structured.getTravelStyle().name() : null);
            up.setFavoriteCategories(structured.getFavoriteCategories() != null
                    ? structured.getFavoriteCategories()
                    : List.of());
            up.setPreferredLanguage(structured.getPreferredLanguage() != null
                    ? structured.getPreferredLanguage()
                    : "tr");
        } else {
            up.setFavoriteCategories(List.of());
            up.setPreferredLanguage("tr");
        }
        up.setEventInterest(extractEventInterest(aiPrefs));

        List<AiChatDto.AvailableEventAi> avail = events.stream()
                .map(EventRecommendationService::toAvailableEventAi)
                .collect(Collectors.toList());

        AiChatDto.EventRecommendAiRequest req = new AiChatDto.EventRecommendAiRequest();
        req.setRouteSummary(rs);
        req.setUserPreferences(up);
        req.setAvailableEvents(avail);
        return req;
    }

    private static String extractEventInterest(List<AiChatDto.ExtractedPreference> prefs) {
        if (prefs == null) {
            return null;
        }
        return prefs.stream()
                .filter(p -> p.getPreferenceKey() != null
                        && "event_interest".equalsIgnoreCase(p.getPreferenceKey().trim()))
                .map(AiChatDto.ExtractedPreference::getPreferenceValue)
                .filter(v -> v != null && !v.isBlank())
                .findFirst()
                .orElse(null);
    }

    private static AiChatDto.AvailableEventAi toAvailableEventAi(EventDTO e) {
        AiChatDto.AvailableEventAi a = new AiChatDto.AvailableEventAi();
        a.setId(e.getId());
        a.setName(e.getName());
        a.setDescription(e.getDescription());
        a.setStartTime(e.getStartTime());
        a.setEndTime(e.getEndTime());
        a.setVenueName(e.getVenueName());
        a.setCategory(e.getCategory());
        a.setLatitude(e.getLatitude());
        a.setLongitude(e.getLongitude());
        return a;
    }

    private static List<EventDTO> sortByStartTime(List<EventDTO> events) {
        return events.stream()
                .sorted(Comparator.comparing(EventDTO::getStartTime, Comparator.nullsLast(Comparator.naturalOrder())))
                .collect(Collectors.toList());
    }

    private static List<RecommendedEvent> buildFromAiRecommendResponse(
            List<EventDTO> filtered,
            AiChatDto.EventRecommendAiResponse response) {
        Map<String, EventDTO> byId = new HashMap<>();
        for (EventDTO e : filtered) {
            if (e.getId() != null) {
                byId.putIfAbsent(e.getId(), e);
            }
        }
        List<RecommendedEvent> out = new ArrayList<>();
        for (AiChatDto.RecommendedEventResultAi item : response.getRecommendedEvents()) {
            if (item == null || item.getEventId() == null) {
                continue;
            }
            EventDTO e = byId.get(item.getEventId());
            if (e == null) {
                continue;
            }
            out.add(toRecommended(e, item));
        }
        return out;
    }

    private static RecommendedEvent toRecommended(EventDTO e, AiChatDto.RecommendedEventResultAi ai) {
        String ticketLink = e.getTicketLink();
        if (ticketLink == null || ticketLink.isBlank()) {
            ticketLink = e.getLink();
        }
        return RecommendedEvent.builder()
                .id(e.getId())
                .name(e.getName())
                .description(e.getDescription())
                .thumbnail(e.getThumbnail())
                .startTime(e.getStartTime())
                .endTime(e.getEndTime())
                .venueName(e.getVenueName())
                .fullAddress(e.getFullAddress())
                .latitude(e.getLatitude())
                .longitude(e.getLongitude())
                .category(e.getCategory())
                .ticketLink(ticketLink)
                .matchedDay(ai != null ? ai.getMatchedDay() : null)
                .matchReason(ai != null ? ai.getMatchReason() : null)
                .relevanceScore(ai != null ? ai.getRelevanceScore() : null)
                .build();
    }
}
