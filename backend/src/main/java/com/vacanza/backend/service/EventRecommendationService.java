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
    public EventRecommendationResponse getRecommendations(UUID routeId, User user) {
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

        EventSearchRequestDTO request = new EventSearchRequestDTO();
        request.setCity(city);
        request.setStartDate(route.getGeneratedAt().toLocalDate());
        request.setEndDate(computeEndDate(request.getStartDate(), totalDays));
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

        int totalFound = filtered.size();
        if (totalFound == 0) {
            return EventRecommendationResponse.builder()
                    .message(null)
                    .events(List.of())
                    .totalFound(0)
                    .hasRecommendations(false)
                    .build();
        }

        AiChatDto.EventRankingRequest rankingRequest = buildRankingRequest(routeData, rawDestination, totalDays, filtered);
        Optional<AiChatDto.EventRankingAiResponse> aiRanked = aiServiceClient.rankRouteEvents(user.getUserId(), rankingRequest);

        if (aiRanked.isPresent()
                && aiRanked.get().getRankedEvents() != null
                && !aiRanked.get().getRankedEvents().isEmpty()) {
            List<RecommendedEvent> ranked = buildFromAiRanking(filtered, aiRanked.get());
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

    private static AiChatDto.EventRankingRequest buildRankingRequest(
            AiChatDto.RouteData routeData,
            String destination,
            int totalDays,
            List<EventDTO> events) {
        List<AiChatDto.RouteDaySummaryForAi> routeDays = new ArrayList<>();
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
                routeDays.add(new AiChatDto.RouteDaySummaryForAi(day.getDay(), day.getTitle(), cats));
            }
        }

        List<AiChatDto.EventBriefForRanking> briefs = events.stream()
                .map(EventRecommendationService::toBrief)
                .collect(Collectors.toList());

        AiChatDto.EventRankingRequest req = new AiChatDto.EventRankingRequest();
        req.setDestination(destination);
        req.setTotalDays(totalDays);
        req.setRouteDays(routeDays);
        req.setEvents(briefs);
        return req;
    }

    private static AiChatDto.EventBriefForRanking toBrief(EventDTO e) {
        AiChatDto.EventBriefForRanking b = new AiChatDto.EventBriefForRanking();
        b.setId(e.getId());
        b.setName(e.getName());
        b.setDescription(e.getDescription());
        b.setStartTime(e.getStartTime());
        b.setCategory(e.getCategory());
        b.setVenueName(e.getVenueName());
        return b;
    }

    private static List<EventDTO> sortByStartTime(List<EventDTO> events) {
        return events.stream()
                .sorted(Comparator.comparing(EventDTO::getStartTime, Comparator.nullsLast(Comparator.naturalOrder())))
                .collect(Collectors.toList());
    }

    private static List<RecommendedEvent> buildFromAiRanking(
            List<EventDTO> filtered,
            AiChatDto.EventRankingAiResponse response) {
        Map<String, EventDTO> byId = new HashMap<>();
        for (EventDTO e : filtered) {
            if (e.getId() != null) {
                byId.putIfAbsent(e.getId(), e);
            }
        }
        List<RecommendedEvent> out = new ArrayList<>();
        for (AiChatDto.EventRankingItem item : response.getRankedEvents()) {
            if (item == null || item.getId() == null) {
                continue;
            }
            EventDTO e = byId.get(item.getId());
            if (e == null) {
                continue;
            }
            out.add(toRecommended(e, item));
        }
        return out;
    }

    private static RecommendedEvent toRecommended(EventDTO e, AiChatDto.EventRankingItem ai) {
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
