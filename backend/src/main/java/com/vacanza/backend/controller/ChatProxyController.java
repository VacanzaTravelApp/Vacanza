package com.vacanza.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.integration.ai.AiServiceClient;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import com.vacanza.backend.integration.MapboxPoiSearchClient;
import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.AiRouteService;
import com.vacanza.backend.service.UserInfoService;
import com.vacanza.backend.service.UserPreferenceAiService;
import com.vacanza.backend.service.UserPreferencesService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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
        private final ObjectMapper objectMapper;
        private final MapboxPoiSearchClient mapboxPoiSearchClient;

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

                // Agentic itinerary flow (backend-orchestrated):
                // If AI responded with a tool_call JSON for search_pois, we execute it here (as the authenticated backend),
                // then call AI again with the POI tool result marker to get final route_data (with coordinates).
                try {
                        if (response != null && response.getContent() != null) {
                                var toolCall = tryParseToolCall(response.getContent());
                                if (toolCall != null && "search_pois".equalsIgnoreCase(toolCall.tool)) {
                                        var pois = executePoiSearchTool(toolCall.destination, toolCall.categories);
                                        if (pois.isEmpty()) {
                                                log.warn("POI tool returned empty list for destination='{}' categories={}", toolCall.destination, toolCall.categories);
                                        }
                                        // Send tool result back to AI service (turn 2)
                                        var toolMsg = new AiChatDto.MessageSendRequest();
                                        // Include tool_call JSON first (for days/travel_style), then tool result marker.
                                        // AI service parses the marker prefix and uses POIs to build route_data.
                                        toolMsg.setContent(objectMapper.writeValueAsString(toolCall) + "\n"
                                                + "__TOOL_RESULT__search_pois__" + objectMapper.writeValueAsString(pois));
                                        AiChatDto.MessageSendResponse turn2 = aiServiceClient
                                                        .sendMessage(user.getUserId(), conversationId, toolMsg, profile, existingAiPrefs)
                                                        .block();
                                        if (turn2 != null) {
                                                response = turn2;
                                        }
                                }
                        }
                } catch (Exception e) {
                        log.warn("Agentic POI flow failed (fallback to normal): {}", e.getMessage());
                }

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
                                // Route data already contains coordinates (agentic POI search flow).
                                saveRoute(user, conversationId, response.getRouteData());
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

        private void saveRoute(User user, UUID conversationId, AiChatDto.RouteData routeData) {
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

        private record PoiToolCall(String tool, String destination, Integer days, String travelStyle, List<String> categories) {}

        private PoiToolCall tryParseToolCall(String content) {
                try {
                        JsonNode n = objectMapper.readTree(content);
                        if (n == null || !n.isObject()) return null;
                        String tool = n.path("tool").asText(null);
                        if (tool == null) return null;
                        String destination = n.path("destination").asText(null);
                        if (destination == null || destination.isBlank()) return null;
                        Integer days = n.hasNonNull("days") ? n.path("days").asInt() : null;
                        String travelStyle = n.path("travel_style").asText(null);
                        var catsNode = n.path("categories");
                        List<String> cats = List.of();
                        if (catsNode != null && catsNode.isArray()) {
                                cats = new java.util.ArrayList<>();
                                for (var c : catsNode) {
                                        if (c != null && c.isTextual()) {
                                                String v = c.asText();
                                                if (v != null && !v.isBlank()) cats.add(v);
                                        }
                                }
                        }
                        return new PoiToolCall(tool, destination, days, travelStyle, cats);
                } catch (Exception e) {
                        return null;
                }
        }

        private List<PoiResult> executePoiSearchTool(String destination, List<String> categories) {
                var destOpt = mapboxPoiSearchClient.geocodeDestination(destination).blockOptional();
                if (destOpt.isEmpty()) return List.of();
                var dest = destOpt.get();
                if (categories == null || categories.isEmpty()) return List.of();

                List<PoiResult> all = new java.util.ArrayList<>();
                for (String c : categories) {
                        if (c == null || c.isBlank()) continue;
                        var pois = mapboxPoiSearchClient
                                        .searchByCategory(c, dest.getMinLon(), dest.getMinLat(), dest.getMaxLon(), dest.getMaxLat())
                                        .blockOptional()
                                        .orElse(List.of());
                        all.addAll(pois);
                }

                // dedupe by name (case-insensitive)
                java.util.Map<String, PoiResult> dedup = new java.util.LinkedHashMap<>();
                for (PoiResult p : all) {
                        if (p == null || p.getName() == null || p.getName().isBlank()) continue;
                        String k = p.getName().toLowerCase(java.util.Locale.ROOT);
                        dedup.putIfAbsent(k, p);
                }
                return new java.util.ArrayList<>(dedup.values());
        }
}
