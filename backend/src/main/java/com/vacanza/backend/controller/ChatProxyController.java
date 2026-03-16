package com.vacanza.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.integration.MapboxGeocodingClient;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.integration.ai.AiServiceClient;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.AiRouteService;
import com.vacanza.backend.service.UserInfoService;
import com.vacanza.backend.service.UserPreferenceAiService;
import com.vacanza.backend.service.UserPreferencesService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/chat")
@RequiredArgsConstructor
public class ChatProxyController {

        private final AiServiceClient aiServiceClient;
        private final CurrentUserProvider currentUserProvider;
        private final UserInfoService userInfoService;
        private final UserPreferencesService userPreferencesService;
        private final UserPreferenceAiService userPreferenceAiService;
        private final AiRouteService aiRouteService;
        private final MapboxGeocodingClient mapboxGeocodingClient;
        private final ObjectMapper objectMapper;

        @PostMapping("/conversations")
        public ResponseEntity<AiChatDto.ConversationCreateResponse> createConversation() {
                User user = currentUserProvider.getCurrentUserEntity();
                return ResponseEntity.ok(
                                aiServiceClient.createConversation(user.getUserId()).block());
        }

        @GetMapping("/conversations")
        public ResponseEntity<List<AiChatDto.ConversationListItem>> listConversations(
                        @RequestParam(required = false) Integer limit,
                        @RequestParam(required = false) Integer offset) {
                User user = currentUserProvider.getCurrentUserEntity();
                List<AiChatDto.ConversationListItem> list = aiServiceClient
                                .listConversations(user.getUserId(), limit, offset)
                                .block();
                return ResponseEntity.ok(list);
        }

        @PostMapping("/conversations/{conversationId}/messages")
        public ResponseEntity<AiChatDto.MessageSendResponse> sendMessage(
                        @PathVariable UUID conversationId,
                        @RequestBody AiChatDto.MessageSendRequest body) {
                User user = currentUserProvider.getCurrentUserEntity();

                var infoDto = userInfoService.getUserInfoByUser(user).orElse(null);
                var prefsDto = userPreferencesService.getPreferencesByUser(user).orElse(null);
                UserProfileForAi profile = UserProfileForAi.from(infoDto, prefsDto);

                var existingAiPrefs = userPreferenceAiService.getExistingPreferences(user);

                AiChatDto.MessageSendResponse response = aiServiceClient
                                .sendMessage(user.getUserId(), conversationId, body, profile, existingAiPrefs)
                                .block();

                try {
                        if (response != null && response.getExtractedPreferences() != null
                                        && !response.getExtractedPreferences().isEmpty()) {
                                userPreferenceAiService.saveExtractedPreferences(
                                                user, response.getExtractedPreferences());
                        }
                } catch (Exception e) {
                        log.warn("Failed to save extracted preferences (non-blocking): {}", e.getMessage());
                }

                try {
                        if (response != null && response.getRouteData() != null) {
                                geocodeAndSaveRoute(user, conversationId, response.getRouteData());
                        }
                } catch (Exception e) {
                        log.warn("Failed to process route data (non-blocking): {}", e.getMessage());
                }

                return ResponseEntity.ok(response);
        }

        @GetMapping("/conversations/{conversationId}/messages")
        public ResponseEntity<List<AiChatDto.MessageItem>> getMessages(
                        @PathVariable UUID conversationId,
                        @RequestParam(required = false) Integer limit,
                        @RequestParam(required = false) Integer offset) {
                User user = currentUserProvider.getCurrentUserEntity();
                List<AiChatDto.MessageItem> list = aiServiceClient
                                .getMessages(user.getUserId(), conversationId, limit, offset)
                                .block();
                return ResponseEntity.ok(list);
        }

        private static final int MAX_GEOCODE_WAYPOINTS = 20;

        private void geocodeAndSaveRoute(User user, UUID conversationId,
                        AiChatDto.RouteData routeData) {
                if (routeData.getDays() == null) return;

                // Geocode ALL waypoints via Mapbox — AI sets lat/lon to null by design.
                List<AiChatDto.RouteWaypoint> toGeocode = routeData.getDays().stream()
                                .filter(d -> d.getWaypoints() != null)
                                .flatMap(d -> d.getWaypoints().stream())
                                .filter(w -> w.getName() != null && !w.getName().isBlank())
                                .limit(MAX_GEOCODE_WAYPOINTS)
                                .toList();

                if (!toGeocode.isEmpty()) {
                        String dest = routeData.getDestination() != null
                                        ? routeData.getDestination() : "";

                        // Geocode destination first → get city center (proximity bias) + country code
                        var destResult = mapboxGeocodingClient.geocode(dest).blockOptional();
                        Double biasLon = destResult.map(MapboxGeocodingClient.GeocodingResult::getLon).orElse(null);
                        Double biasLat = destResult.map(MapboxGeocodingClient.GeocodingResult::getLat).orElse(null);
                        String countryCode = destResult.map(MapboxGeocodingClient.GeocodingResult::getCountryCode).orElse(null);

                        // Geocode each waypoint with proximity bias + country filter (max 4 concurrent)
                        Flux.fromIterable(toGeocode)
                                        .flatMap(wp -> mapboxGeocodingClient
                                                        .geocode(wp.getName() + ", " + dest, biasLon, biasLat, countryCode)
                                                        .doOnNext(result -> {
                                                                wp.setLatitude(result.getLat());
                                                                wp.setLongitude(result.getLon());
                                                        })
                                                        .onErrorResume(e -> {
                                                                log.debug("Geocode skipped for '{}': {}",
                                                                                wp.getName(), e.getMessage());
                                                                return reactor.core.publisher.Mono.empty();
                                                        }),
                                                        4)
                                        .blockLast();
                }

                try {
                        String routeJson = objectMapper.writeValueAsString(routeData);
                        aiRouteService.saveRoute(
                                        user, conversationId,
                                        routeData.getTitle(),
                                        routeData.getDestination(),
                                        routeData.getTotalDays(),
                                        routeJson);
                } catch (Exception e) {
                        log.warn("Failed to save route to DB: {}", e.getMessage());
                }
        }
}
