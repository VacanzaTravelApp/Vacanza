package com.vacanza.backend.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.vacanza.backend.dto.PolygonRouteErrorResponse;
import com.vacanza.backend.dto.PolygonRouteRequest;
import com.vacanza.backend.dto.ReplanDayFromPolygonRequest;
import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.integration.ai.AiServiceClient;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import com.vacanza.backend.integration.MapboxPoiSearchClient;
import com.vacanza.backend.integration.MapboxPoiSearchClient.DestinationGeocodeResult;
import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.util.PolygonRouteGeometry;
import com.vacanza.backend.service.AiRouteService;
import com.vacanza.backend.service.RouteSummaryMessageService;
import com.vacanza.backend.dto.weather.WeatherPlanningForecast;
import com.vacanza.backend.dto.internal.PersonalizedPoiParams;
import com.vacanza.backend.service.PersonalizedPoiSelector;
import com.vacanza.backend.service.RouteTimelineService;
import com.vacanza.backend.service.UserInfoService;
import com.vacanza.backend.service.WeatherService;
import com.vacanza.backend.service.UserPreferenceAiService;
import com.vacanza.backend.service.UserPreferencesService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/chat")
@RequiredArgsConstructor
public class ChatProxyController {

        /**
         * Default POI categories when the client sends none (aligned with general itinerary tool flow).
         * Broad set: sightseeing + dining + leisure for a rich, personalizable POI pool.
         */
        private static final List<String> DEFAULT_POLYGON_CATEGORIES = List.of(
                        "museum", "monument", "historic_site", "church", "park", "neighborhood",
                        "landmark", "art_gallery", "tourist_attraction", "restaurant", "cafe", "bar");

        /**
         * Dining categories that should be fetched using a tight bbox around sightseeing POIs,
         * not the full destination bbox. This keeps recommended restaurants/cafes near the
         * day's actual sightseeing spots.
         */
        private static final java.util.Set<String> DINING_CATS = java.util.Set.of(
                        "restaurant", "cafe", "bar", "fast_food",
                        "nightclub", "nightlife", "pub", "food", "market", "bakery");

        /** Resolve search categories from request or fall back to defaults. */
        private List<String> resolveSearchCategories(List<String> fromRequest) {
                if (fromRequest != null && !fromRequest.isEmpty()) {
                        List<String> cleaned = new ArrayList<>();
                        for (String c : fromRequest) {
                                if (c != null && !c.isBlank()) {
                                        cleaned.add(c.trim());
                                }
                        }
                        if (!cleaned.isEmpty()) {
                                return cleaned;
                        }
                }
                return new ArrayList<>(DEFAULT_POLYGON_CATEGORIES);
        }

        /** Minimum distinct POIs inside the polygon after search + dedup. */
        private static final int MIN_POIS_IN_POLYGON = 3;

        /** Single-day replan can use a smaller drawn area. */
        private static final int MIN_POIS_REPLAN_DAY = 2;

        private final AiServiceClient aiServiceClient;
        private final CurrentUserProvider currentUserProvider;
        private final UserInfoService userInfoService;
        private final UserPreferencesService userPreferencesService;
        private final UserPreferenceAiService userPreferenceAiService;
        private final AiRouteService aiRouteService;
        private final RouteSummaryMessageService routeSummaryMessageService;
        private final ObjectMapper objectMapper;
        private final MapboxPoiSearchClient mapboxPoiSearchClient;
        private final RouteTimelineService routeTimelineService;
        private final WeatherService weatherService;
        private final PersonalizedPoiSelector personalizedPoiSelector;

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
                WeatherPlanningForecast routePlanningWeather = null;
                try {
                        if (response != null && response.getContent() != null) {
                                String toolJsonRaw = extractLeadingJsonObject(response.getContent());
                                var toolCall = parseToolCallFromJson(toolJsonRaw);
                                if (toolCall != null && "search_pois".equalsIgnoreCase(toolCall.tool)) {
                                        var exec = executePoiSearchWithWeather(
                                                        toolCall.destination,
                                                        toolCall.categories,
                                                        toolCall.mustVisit,
                                                        toolCall.days,
                                                        profile,
                                                        user.getUserId());
                                        var pois = exec.pois();
                                        routePlanningWeather = exec.planningWeather();
                                        if (pois.isEmpty()) {
                                                log.warn("POI tool returned empty list for destination='{}' categories={}", toolCall.destination, toolCall.categories);
                                        }
                                        // Send tool result back to AI service (turn 2).
                                        // Reuse the model's original JSON for line 1 so snake_case (e.g. travel_style) matches Python.
                                        var toolMsg = new AiChatDto.MessageSendRequest();
                                        StringBuilder toolBody = new StringBuilder();
                                        toolBody.append(toolJsonRaw).append("\n");
                                        toolBody.append("__TOOL_RESULT__search_pois__")
                                                        .append(objectMapper.writeValueAsString(pois));
                                        try {
                                                if (routePlanningWeather != null
                                                                && (!routePlanningWeather.daily().isEmpty()
                                                                                || !routePlanningWeather.dayParts().isEmpty())) {
                                                        toolBody.append("\n__WEATHER_CONTEXT__")
                                                                        .append(objectMapper.writeValueAsString(routePlanningWeather));
                                                }
                                        } catch (Exception wx) {
                                                log.warn("Weather context omitted (serialization failed): {}", wx.getMessage());
                                        }
                                        toolMsg.setContent(toolBody.toString());
                                        AiChatDto.MessageSendResponse turn2 = aiServiceClient
                                                        .sendMessage(user.getUserId(), conversationId, toolMsg, profile, existingAiPrefs)
                                                        .block();
                                        if (turn2 != null) {
                                                response = turn2;
                                        }
                                }
                        }
                } catch (Exception e) {
                        log.warn("Agentic POI flow failed (fallback to normal): {}", e.toString(), e);
                }

                saveExtractedPreferencesIfAny(user, response);
                applyRouteEnrichmentAndSave(user, conversationId, response, routePlanningWeather, profile);

                return ResponseEntity.ok(response);
        }

        /**
         * Generate an itinerary from a user-drawn map polygon (web). Validates geometry, searches POIs inside the
         * polygon (Mapbox bbox + point-in-polygon filter), then runs the same AI “Turn 2” flow as the chat tool.
         */
        @PostMapping("/routes/from-polygon")
        public ResponseEntity<?> createRouteFromPolygon(@RequestBody PolygonRouteRequest body) {
                User user = currentUserProvider.getCurrentUserEntity();
                List<double[]> ring;
                try {
                        ring = PolygonRouteGeometry.normalizeRing(body.getCoordinates());
                } catch (IllegalArgumentException ex) {
                        return ResponseEntity.badRequest()
                                        .body(new PolygonRouteErrorResponse("INVALID_POLYGON", ex.getMessage()));
                }
                double bboxKm2 = PolygonRouteGeometry.bboxAreaKm2(ring);
                if (bboxKm2 > PolygonRouteGeometry.MAX_BBOX_AREA_KM2 || !Double.isFinite(bboxKm2)) {
                        return ResponseEntity.badRequest()
                                        .body(new PolygonRouteErrorResponse(
                                                        "POLYGON_TOO_LARGE",
                                                        "Selected area is too large (max bounding area ~"
                                                                        + (int) PolygonRouteGeometry.MAX_BBOX_AREA_KM2
                                                                        + " km²). Draw a smaller region."));
                }

                int totalDays = body.getTotalDays() != null ? body.getTotalDays() : 3;
                totalDays = Math.min(Math.max(totalDays, 1), 16);
                String travelStyle = body.getTravelStyle() != null && !body.getTravelStyle().isBlank()
                                ? body.getTravelStyle().trim()
                                : "general";
                List<String> categories = resolveSearchCategories(body.getCategories());

                var infoDtoPoly = userInfoService.getUserInfoByUser(user).orElse(null);
                var prefsDtoPoly = userPreferencesService.getPreferencesByUser(user).orElse(null);
                UserProfileForAi profilePoly = UserProfileForAi.from(infoDtoPoly, prefsDtoPoly);

                PoiToolExecutionResult exec = executePoiSearchForPolygon(
                                ring, categories, totalDays, profilePoly, user.getUserId());
                if (exec.pois().size() < MIN_POIS_IN_POLYGON) {
                        return ResponseEntity.badRequest()
                                        .body(new PolygonRouteErrorResponse(
                                                        "INSUFFICIENT_POIS_IN_AREA",
                                                        "Not enough places found inside the drawn area. Try a larger area or different categories."));
                }

                double[] c = PolygonRouteGeometry.centroid(ring);
                String destinationLabel = String.format(Locale.US, "Map area (%.4f, %.4f)", c[1], c[0]);

                String toolJsonRaw;
                try {
                        Map<String, Object> tool = new LinkedHashMap<>();
                        tool.put("tool", "search_pois");
                        tool.put("destination", destinationLabel);
                        tool.put("days", totalDays);
                        tool.put("travel_style", travelStyle);
                        tool.put("categories", categories);
                        toolJsonRaw = objectMapper.writeValueAsString(tool);
                } catch (Exception e) {
                        log.warn("Failed to build tool JSON for polygon route: {}", e.getMessage());
                        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                        .body(new PolygonRouteErrorResponse("INTERNAL_ERROR", "Could not build route request."));
                }

                AiChatDto.ConversationCreateResponse conv = aiServiceClient.createConversation(user.getUserId()).block();
                if (conv == null || conv.getId() == null) {
                        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                                        .body(new PolygonRouteErrorResponse("CONVERSATION_CREATE_FAILED", "Could not start conversation."));
                }
                UUID conversationId = conv.getId();

                UserProfileForAi profile = profilePoly;
                var existingAiPrefs = userPreferenceAiService.getExistingPreferences(user);

                StringBuilder toolBody = new StringBuilder();
                toolBody.append("[Polygon route request]\n");
                toolBody.append(toolJsonRaw).append("\n");
                try {
                        toolBody.append("__TOOL_RESULT__search_pois__")
                                        .append(objectMapper.writeValueAsString(exec.pois()));
                        if (exec.planningWeather() != null
                                        && (!exec.planningWeather().daily().isEmpty()
                                                        || !exec.planningWeather().dayParts().isEmpty())) {
                                toolBody.append("\n__WEATHER_CONTEXT__")
                                                .append(objectMapper.writeValueAsString(exec.planningWeather()));
                        }
                } catch (Exception e) {
                        log.warn("Polygon route tool body serialization failed: {}", e.getMessage());
                        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                        .body(new PolygonRouteErrorResponse("INTERNAL_ERROR", "Could not build AI request."));
                }

                AiChatDto.MessageSendRequest toolMsg = new AiChatDto.MessageSendRequest();
                toolMsg.setContent(toolBody.toString());
                AiChatDto.MessageSendResponse response = aiServiceClient
                                .sendMessage(user.getUserId(), conversationId, toolMsg, profile, existingAiPrefs)
                                .block();

                if (response == null) {
                        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                                        .body(new PolygonRouteErrorResponse("AI_UNAVAILABLE", "No response from AI service."));
                }

                saveExtractedPreferencesIfAny(user, response);
                applyRouteEnrichmentAndSave(user, conversationId, response, exec.planningWeather(), profile);

                response.setConversationId(conversationId);
                return ResponseEntity.ok(response);
        }

        /**
         * Replace one day of the conversation's latest saved route using POIs inside a user-drawn polygon.
         * Keeps the same chat thread; persists the updated route like other map/chat flows.
         */
        @PostMapping("/routes/replan-day-from-polygon")
        public ResponseEntity<?> replanDayFromPolygon(@RequestBody ReplanDayFromPolygonRequest body) {
                User user = currentUserProvider.getCurrentUserEntity();
                if (body == null || body.getConversationId() == null) {
                        return ResponseEntity.badRequest()
                                        .body(new PolygonRouteErrorResponse("INVALID_REQUEST", "conversationId is required."));
                }
                if (body.getDay() == null || body.getDay() < 1) {
                        return ResponseEntity.badRequest()
                                        .body(new PolygonRouteErrorResponse("INVALID_DAY", "day must be >= 1."));
                }
                List<double[]> ring;
                try {
                        ring = PolygonRouteGeometry.normalizeRing(body.getCoordinates());
                } catch (IllegalArgumentException ex) {
                        return ResponseEntity.badRequest()
                                        .body(new PolygonRouteErrorResponse("INVALID_POLYGON", ex.getMessage()));
                }
                double bboxKm2 = PolygonRouteGeometry.bboxAreaKm2(ring);
                if (bboxKm2 > PolygonRouteGeometry.MAX_BBOX_AREA_KM2 || !Double.isFinite(bboxKm2)) {
                        return ResponseEntity.badRequest()
                                        .body(new PolygonRouteErrorResponse(
                                                        "POLYGON_TOO_LARGE",
                                                        "Selected area is too large (max bounding area ~"
                                                                        + (int) PolygonRouteGeometry.MAX_BBOX_AREA_KM2
                                                                        + " km²). Draw a smaller region."));
                }

                UUID conversationId = body.getConversationId();
                List<AiRoute> existingRoutes = aiRouteService.getRoutesForConversation(user, conversationId);
                if (existingRoutes.isEmpty()) {
                        return ResponseEntity.badRequest()
                                        .body(new PolygonRouteErrorResponse(
                                                        "NO_SAVED_ROUTE",
                                                        "This conversation has no saved route yet. Create a route in chat or from the map first."));
                }
                AiRoute latest = existingRoutes.get(existingRoutes.size() - 1);
                AiChatDto.RouteData existingRouteData;
                try {
                        existingRouteData = objectMapper.readValue(latest.getRouteJson(), AiChatDto.RouteData.class);
                } catch (Exception e) {
                        log.warn("Failed to parse saved route JSON for replan: {}", e.getMessage());
                        return ResponseEntity.badRequest()
                                        .body(new PolygonRouteErrorResponse("INVALID_SAVED_ROUTE", "Could not read saved route."));
                }
                int totalDays = existingRouteData.getTotalDays();
                if (body.getDay() > totalDays) {
                        return ResponseEntity.badRequest()
                                        .body(new PolygonRouteErrorResponse(
                                                        "DAY_OUT_OF_RANGE",
                                                        "day must be between 1 and " + totalDays + " for this route."));
                }

                String travelStyle = body.getTravelStyle() != null && !body.getTravelStyle().isBlank()
                                ? body.getTravelStyle().trim()
                                : "general";
                List<String> categories = resolveSearchCategories(body.getCategories());

                var infoDtoReplan = userInfoService.getUserInfoByUser(user).orElse(null);
                var prefsDtoReplan = userPreferencesService.getPreferencesByUser(user).orElse(null);
                UserProfileForAi profile = UserProfileForAi.from(infoDtoReplan, prefsDtoReplan);

                PoiToolExecutionResult exec = executePoiSearchForPolygon(
                                ring, categories, totalDays, profile, user.getUserId());
                if (exec.pois().size() < MIN_POIS_REPLAN_DAY) {
                        return ResponseEntity.badRequest()
                                        .body(new PolygonRouteErrorResponse(
                                                        "INSUFFICIENT_POIS_IN_AREA",
                                                        "Not enough places found inside the drawn area. Try a larger area or different categories."));
                }

                String existingRouteCanonical;
                try {
                        existingRouteCanonical = objectMapper.writeValueAsString(existingRouteData);
                } catch (Exception e) {
                        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                        .body(new PolygonRouteErrorResponse("INTERNAL_ERROR", "Could not serialize route."));
                }

                String toolJsonRaw;
                try {
                        double[] c = PolygonRouteGeometry.centroid(ring);
                        String destinationLabel = String.format(Locale.US, "Map area (%.4f, %.4f)", c[1], c[0]);
                        Map<String, Object> tool = new LinkedHashMap<>();
                        tool.put("tool", "search_pois");
                        tool.put("destination", destinationLabel);
                        tool.put("days", totalDays);
                        tool.put("travel_style", travelStyle);
                        tool.put("categories", categories);
                        toolJsonRaw = objectMapper.writeValueAsString(tool);
                } catch (Exception e) {
                        log.warn("Failed to build tool JSON for replan-day: {}", e.getMessage());
                        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                        .body(new PolygonRouteErrorResponse("INTERNAL_ERROR", "Could not build route request."));
                }

                var existingAiPrefs = userPreferenceAiService.getExistingPreferences(user);

                StringBuilder toolBody = new StringBuilder();
                toolBody.append("[Replan day request]\n");
                toolBody.append("Day: ").append(body.getDay().intValue()).append("\n");
                toolBody.append(toolJsonRaw).append("\n");
                try {
                        toolBody.append("__TOOL_RESULT__search_pois__")
                                        .append(objectMapper.writeValueAsString(exec.pois()));
                        if (exec.planningWeather() != null
                                        && (!exec.planningWeather().daily().isEmpty()
                                                        || !exec.planningWeather().dayParts().isEmpty())) {
                                toolBody.append("\n__WEATHER_CONTEXT__")
                                                .append(objectMapper.writeValueAsString(exec.planningWeather()));
                        }
                } catch (Exception e) {
                        log.warn("Replan-day tool body serialization failed: {}", e.getMessage());
                        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                        .body(new PolygonRouteErrorResponse("INTERNAL_ERROR", "Could not build AI request."));
                }
                toolBody.append("\n__EXISTING_ROUTE__\n");
                toolBody.append(existingRouteCanonical);

                AiChatDto.MessageSendRequest toolMsg = new AiChatDto.MessageSendRequest();
                toolMsg.setContent(toolBody.toString());
                AiChatDto.MessageSendResponse response = aiServiceClient
                                .sendMessage(user.getUserId(), conversationId, toolMsg, profile, existingAiPrefs)
                                .block();

                if (response == null) {
                        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                                        .body(new PolygonRouteErrorResponse("AI_UNAVAILABLE", "No response from AI service."));
                }

                saveExtractedPreferencesIfAny(user, response);
                applyRouteEnrichmentAndSave(user, conversationId, response, exec.planningWeather(), profile);

                response.setConversationId(conversationId);
                return ResponseEntity.ok(response);
        }

        private void saveExtractedPreferencesIfAny(User user, AiChatDto.MessageSendResponse response) {
                try {
                        if (response != null && response.getExtractedPreferences() != null
                                        && !response.getExtractedPreferences().isEmpty()) {
                                userPreferenceAiService.saveExtractedPreferences(
                                                user, response.getExtractedPreferences());
                        }
                } catch (Exception e) {
                        log.warn("Failed to save extracted preferences (non-blocking): {}", e.getMessage());
                }
        }

        private void applyRouteEnrichmentAndSave(
                        User user,
                        UUID conversationId,
                        AiChatDto.MessageSendResponse response,
                        WeatherPlanningForecast routePlanningWeather,
                        UserProfileForAi profile) {
                try {
                        if (response != null && response.getRouteData() != null) {
                                resolveNullCoordinates(response.getRouteData());
                                if (routePlanningWeather != null && !routePlanningWeather.daily().isEmpty()) {
                                        response.getRouteData().setWeatherForecast(routePlanningWeather.daily());
                                }
                                if (routePlanningWeather != null && !routePlanningWeather.dayParts().isEmpty()) {
                                        response.getRouteData().setWeatherDayParts(routePlanningWeather.dayParts());
                                }
                                routeTimelineService.enrichTimeline(response.getRouteData(), profile);
                                UUID savedRouteId = saveRoute(user, conversationId, response.getRouteData());
                                if (savedRouteId != null) {
                                        response.setRouteId(savedRouteId);
                                }
                                String summaryMessage = routeSummaryMessageService.buildSummaryMessage(
                                                response.getRouteData(), profile);
                                if (summaryMessage != null) {
                                        response.setRouteSummaryMessage(summaryMessage);
                                }
                        }
                } catch (Exception e) {
                        log.warn("Failed to process route data (non-blocking): {}", e.getMessage());
                }
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

        /**
         * Resolve waypoints that have null lat/lon via Mapbox forward search.
         * LLM may add iconic landmarks not in the POI list with null coordinates.
         * <p>
         * Uses the trip destination's bounding box so generic names (e.g. "Blue Mosque") resolve
         * in the correct city instead of a same-named POI elsewhere (e.g. Jakarta).
         */
        private void resolveNullCoordinates(AiChatDto.RouteData routeData) {
                if (routeData == null || routeData.getDays() == null) return;
                String destination = routeData.getDestination();
                double minLon = -180;
                double minLat = -90;
                double maxLon = 180;
                double maxLat = 90;
                if (destination != null && !destination.isBlank()) {
                        var bboxOpt = mapboxPoiSearchClient.geocodeDestination(destination.trim()).blockOptional();
                        if (bboxOpt.isPresent()) {
                                DestinationGeocodeResult g = bboxOpt.get();
                                minLon = g.getMinLon();
                                minLat = g.getMinLat();
                                maxLon = g.getMaxLon();
                                maxLat = g.getMaxLat();
                                log.info("[RESOLVE NULL] bbox from destination '{}' -> {},{},{},{}",
                                                destination, minLon, minLat, maxLon, maxLat);
                        } else {
                                log.warn("[RESOLVE NULL] Could not geocode destination '{}'; forward search may be ambiguous",
                                                destination);
                        }
                }
                for (AiChatDto.DayPlan dayPlan : routeData.getDays()) {
                        if (dayPlan.getWaypoints() == null) continue;
                        for (AiChatDto.RouteWaypoint wp : dayPlan.getWaypoints()) {
                                if (wp.getLatitude() != null && wp.getLongitude() != null) continue;
                                if (wp.getName() == null || wp.getName().isBlank()) continue;
                                try {
                                        var result = mapboxPoiSearchClient.resolvePlace(
                                                        wp.getName(),
                                                        destination != null ? destination : "",
                                                        minLon, minLat, maxLon, maxLat)
                                                .blockOptional();
                                        if (result.isPresent()) {
                                                wp.setLatitude(result.get().getLat());
                                                wp.setLongitude(result.get().getLon());
                                                log.info("[RESOLVE NULL] '{}' -> ({}, {}) ✓", wp.getName(),
                                                                result.get().getLat(), result.get().getLon());
                                        } else {
                                                log.warn("[RESOLVE NULL] All strategies exhausted for '{}' — waypoint has no coordinates",
                                                                wp.getName());
                                        }
                                } catch (Exception e) {
                                        log.warn("[RESOLVE NULL] Failed for '{}': {}", wp.getName(), e.getMessage());
                                }
                        }
                }
        }

        private UUID saveRoute(User user, UUID conversationId, AiChatDto.RouteData routeData) {
                try {
                        String routeJson = objectMapper.writeValueAsString(routeData);
                        AiRoute saved = aiRouteService.saveRoute(
                                        user, conversationId,
                                        routeData.getTitle(),
                                        routeData.getDestination(),
                                        routeData.getTotalDays(),
                                        routeJson);
                        return saved.getRouteId();
                } catch (Exception e) {
                        log.warn("Failed to save route to DB: {}", e.getMessage());
                        return null;
                }
        }

        private record PoiToolCall(String tool, String destination, Integer days, String travelStyle, List<String> categories, List<String> mustVisit) {}

        /**
         * Model output may include markdown fences or prose; extract the first JSON object for tool parsing.
         */
        private static String extractLeadingJsonObject(String content) {
                if (content == null || content.isBlank()) {
                        return null;
                }
                String s = content.trim();
                if (!s.isEmpty() && s.charAt(0) == '\ufeff') {
                        s = s.substring(1).trim();
                }
                if (s.startsWith("```")) {
                        int firstNl = s.indexOf('\n');
                        if (firstNl != -1) {
                                s = s.substring(firstNl + 1);
                        }
                        int fenceEnd = s.lastIndexOf("```");
                        if (fenceEnd > 0) {
                                s = s.substring(0, fenceEnd).trim();
                        }
                }
                int start = s.indexOf('{');
                int end = s.lastIndexOf('}');
                if (start == -1 || end <= start) {
                        return null;
                }
                return s.substring(start, end + 1);
        }

        /** Parse tool fields from JSON (supports snake_case from the model). */
        private PoiToolCall parseToolCallFromJson(String json) {
                if (json == null || json.isBlank()) {
                        return null;
                }
                try {
                        JsonNode n = objectMapper.readTree(json);
                        if (n == null || !n.isObject()) return null;
                        String tool = n.path("tool").asText(null);
                        if (tool == null) return null;
                        String destination = n.path("destination").asText(null);
                        if (destination == null || destination.isBlank()) return null;
                        Integer days = n.hasNonNull("days") ? n.path("days").asInt() : null;
                        String travelStyle = n.hasNonNull("travel_style")
                                        ? n.path("travel_style").asText(null)
                                        : n.path("travelStyle").asText(null);
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
                        var mvNode = n.path("must_visit");
                        List<String> mustVisit = List.of();
                        if (mvNode != null && mvNode.isArray()) {
                                mustVisit = new java.util.ArrayList<>();
                                for (var mv : mvNode) {
                                        if (mv != null && mv.isTextual()) {
                                                String v = mv.asText();
                                                if (v != null && !v.isBlank()) mustVisit.add(v);
                                        }
                                }
                        }
                        return new PoiToolCall(tool, destination, days, travelStyle, cats, mustVisit);
                } catch (Exception e) {
                        log.debug("parseToolCallFromJson failed: {}", e.getMessage());
                        return null;
                }
        }

        private record PoiToolExecutionResult(List<PoiResult> pois, WeatherPlanningForecast planningWeather) {}

        /**
         * Geocode destination, fetch Open-Meteo daily + day-part forecast for trip length, then search POIs in bbox.
         */
        private PoiToolExecutionResult executePoiSearchWithWeather(
                        String destination,
                        List<String> categories,
                        List<String> mustVisit,
                        Integer tripDays,
                        UserProfileForAi profile,
                        java.util.UUID userId) {
                int forecastDays = Math.min(Math.max(tripDays != null && tripDays > 0 ? tripDays : 7, 1), 16);
                var destOpt = mapboxPoiSearchClient.geocodeDestination(destination).blockOptional();
                if (destOpt.isEmpty()) {
                        return new PoiToolExecutionResult(List.of(), new WeatherPlanningForecast(List.of(), List.of()));
                }
                var dest = destOpt.get();
                WeatherPlanningForecast planning = weatherService.getPlanningForecast(
                                dest.getCenterLat(), dest.getCenterLon(), forecastDays);
                List<String> cats = categories != null && !categories.isEmpty()
                        ? new ArrayList<>(categories)
                        : new ArrayList<>(DEFAULT_POLYGON_CATEGORIES);
                if (cats.isEmpty()) {
                        return new PoiToolExecutionResult(List.of(), planning);
                }
                if (!cats.contains("tourist_attraction") && !cats.contains("attraction")) {
                        cats.add("tourist_attraction");
                }

                // Phase 1: fetch sightseeing categories with full destination bbox
                List<String> sightCats = cats.stream()
                                .filter(c -> c != null && !DINING_CATS.contains(c.toLowerCase(java.util.Locale.ROOT)))
                                .toList();
                List<String> diningCats = cats.stream()
                                .filter(c -> c != null && DINING_CATS.contains(c.toLowerCase(java.util.Locale.ROOT)))
                                .toList();

                List<PoiResult> all = new java.util.ArrayList<>();
                for (String c : sightCats) {
                        if (c.isBlank()) continue;
                        var pois = mapboxPoiSearchClient
                                        .searchByCategory(c, dest.getMinLon(), dest.getMinLat(), dest.getMaxLon(), dest.getMaxLat())
                                        .blockOptional()
                                        .orElse(List.of());
                        all.addAll(pois);
                }

                // Phase 2: compute a tight bbox around sightseeing POIs (+1500 m padding)
                // so dining results stay near where the traveller will actually be.
                double[] dBbox = tightBboxWithPaddingMeters(all, dest, 1500.0);

                // Phase 3: fetch dining categories with tight bbox
                for (String c : diningCats) {
                        if (c.isBlank()) continue;
                        var pois = mapboxPoiSearchClient
                                        .searchByCategory(c, dBbox[0], dBbox[1], dBbox[2], dBbox[3])
                                        .blockOptional()
                                        .orElse(List.of());
                        all.addAll(pois);
                }

                // Forward-search each must_visit landmark so iconic places are guaranteed in the pool
                if (mustVisit != null) {
                        for (String placeName : mustVisit) {
                                if (placeName == null || placeName.isBlank()) continue;
                                String query = placeName.contains(",") ? placeName : placeName + ", " + destination;
                                var mvPois = mapboxPoiSearchClient.forwardSearchPoi(query,
                                                dest.getMinLon(), dest.getMinLat(), dest.getMaxLon(), dest.getMaxLat())
                                        .blockOptional().orElse(List.of());
                                all.addAll(mvPois);
                                if (!mvPois.isEmpty()) {
                                        log.info("[MUST_VISIT] '{}' resolved to {} POI(s)", placeName, mvPois.size());
                                }
                        }
                }

                java.util.Map<String, PoiResult> dedup = new java.util.LinkedHashMap<>();
                for (PoiResult p : all) {
                        if (p == null || p.getName() == null || p.getName().isBlank()) continue;
                        String k = p.getName().toLowerCase(java.util.Locale.ROOT);
                        dedup.putIfAbsent(k, p);
                }
                List<PoiResult> merged = personalizedPoiSelector.select(
                                new java.util.ArrayList<>(dedup.values()),
                                profile,
                                PersonalizedPoiParams.forUser(userId));

                // ── POI POOL DIAGNOSTIC LOG ──────────────────────────────────────────
                // Shows exactly what is sent to the AI. Check this first when debugging
                // bad routes: wrong POIs here = backend problem; correct POIs but bad
                // route = AI or post-processing problem.
                long sightCount = merged.stream().filter(p -> !DINING_CATS.contains(
                                (p.getCategory() == null ? "" : p.getCategory()).toLowerCase(java.util.Locale.ROOT))).count();
                long diningCount = merged.size() - sightCount;
                log.info("[POI_POOL] destination='{}' total={} (sight={} dining={})",
                                destination, merged.size(), sightCount, diningCount);
                for (PoiResult p : merged) {
                        log.info("[POI_POOL]   [{}] {} → lat:{} lon:{}",
                                        p.getCategory(), p.getName(), p.getLat(), p.getLon());
                }
                // ─────────────────────────────────────────────────────────────────────

                return new PoiToolExecutionResult(merged, planning);
        }

        /**
         * Compute a bounding box that tightly wraps the given POIs and adds {@code paddingMeters}
         * on every side. Used to restrict dining POI searches to the area where sightseeing happens.
         *
         * <p>Fallback: if {@code pois} has no valid coordinates, returns a small box centred on
         * {@code dest} with radius {@code paddingMeters}.
         *
         * @return [minLon, minLat, maxLon, maxLat]
         */
        /**
         * Maximum distance from the sightseeing centroid that a POI may be and still
         * influence the dining bbox. Outliers beyond this radius (e.g. Yoros Castle 19 km
         * away, Senlikkoy 23 km away) would otherwise stretch the bbox across the whole
         * city and pull in restaurants from totally different districts.
         */
        private static final double CLUSTER_FILTER_RADIUS_M = 7_000.0;

        private static double[] tightBboxWithPaddingMeters(
                        List<PoiResult> pois,
                        DestinationGeocodeResult dest,
                        double paddingMeters) {

                if (pois.isEmpty()) {
                        // No sightseeing POIs — small box around city centre
                        double padLat0 = paddingMeters / 111_000.0;
                        double padLon0 = paddingMeters / (111_000.0 * Math.cos(Math.toRadians(dest.getCenterLat())));
                        return new double[]{
                                dest.getCenterLon() - padLon0, dest.getCenterLat() - padLat0,
                                dest.getCenterLon() + padLon0, dest.getCenterLat() + padLat0
                        };
                }

                // Step 1: compute raw centroid of ALL sightseeing POIs
                double sumLat = 0, sumLon = 0;
                for (PoiResult p : pois) { sumLat += p.getLat(); sumLon += p.getLon(); }
                double centLat = sumLat / pois.size();
                double centLon = sumLon / pois.size();

                // Step 2: keep only POIs within CLUSTER_FILTER_RADIUS_M of the centroid
                // This removes outliers (castles, suburbs, far museums) that would
                // otherwise stretch the bbox across the entire city.
                List<PoiResult> core = pois.stream()
                        .filter(p -> haversineMeters(centLat, centLon, p.getLat(), p.getLon()) <= CLUSTER_FILTER_RADIUS_M)
                        .collect(java.util.stream.Collectors.toList());

                if (core.isEmpty()) {
                        core = pois; // safety: if every POI is an outlier, use all
                }

                log.info("[POI_DINING_BBOX] centroid=({},{}) cluster={}/{} POIs within {}m",
                        centLat, centLon, core.size(), pois.size(), (int) CLUSTER_FILTER_RADIUS_M);

                // Step 3: min/max of the core cluster
                double minLat = Double.MAX_VALUE, maxLat = -Double.MAX_VALUE;
                double minLon = Double.MAX_VALUE, maxLon = -Double.MAX_VALUE;
                for (PoiResult p : core) {
                        minLat = Math.min(minLat, p.getLat());
                        maxLat = Math.max(maxLat, p.getLat());
                        minLon = Math.min(minLon, p.getLon());
                        maxLon = Math.max(maxLon, p.getLon());
                }
                double centerLat = (minLat + maxLat) / 2.0;
                double padLat = paddingMeters / 111_000.0;
                double padLon = paddingMeters / (111_000.0 * Math.cos(Math.toRadians(centerLat)));
                double[] bbox = new double[]{
                        minLon - padLon, minLat - padLat,
                        maxLon + padLon, maxLat + padLat
                };
                log.info("[POI_DINING_BBOX] result: minLon={} minLat={} maxLon={} maxLat={}",
                        bbox[0], bbox[1], bbox[2], bbox[3]);
                return bbox;
        }

        /** Haversine distance in metres between two lat/lon points. */
        private static double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
                final double R = 6_371_000.0;
                double phi1 = Math.toRadians(lat1), phi2 = Math.toRadians(lat2);
                double dPhi = Math.toRadians(lat2 - lat1);
                double dLam = Math.toRadians(lon2 - lon1);
                double a = Math.sin(dPhi / 2) * Math.sin(dPhi / 2)
                        + Math.cos(phi1) * Math.cos(phi2) * Math.sin(dLam / 2) * Math.sin(dLam / 2);
                return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        }

        /**
         * Search Mapbox categories in the polygon bounding box, keep POIs whose coordinates fall inside the ring.
         */
        private PoiToolExecutionResult executePoiSearchForPolygon(
                        List<double[]> ring,
                        List<String> categories,
                        int tripDays,
                        UserProfileForAi profile,
                        java.util.UUID userId) {
                int forecastDays = Math.min(Math.max(tripDays, 1), 16);
                double minLon = PolygonRouteGeometry.minLon(ring);
                double maxLon = PolygonRouteGeometry.maxLon(ring);
                double minLat = PolygonRouteGeometry.minLat(ring);
                double maxLat = PolygonRouteGeometry.maxLat(ring);
                double[] c = PolygonRouteGeometry.centroid(ring);
                WeatherPlanningForecast planning = weatherService.getPlanningForecast(c[1], c[0], forecastDays);

                List<PoiResult> all = new ArrayList<>();
                for (String cat : categories) {
                        if (cat == null || cat.isBlank()) {
                                continue;
                        }
                        var batch = mapboxPoiSearchClient
                                        .searchByCategory(cat, minLon, minLat, maxLon, maxLat)
                                        .blockOptional()
                                        .orElse(List.of());
                        for (PoiResult p : batch) {
                                if (p == null || p.getName() == null || p.getName().isBlank()) {
                                        continue;
                                }
                                if (PolygonRouteGeometry.pointInPolygon(p.getLon(), p.getLat(), ring)) {
                                        all.add(p);
                                }
                        }
                }

                java.util.Map<String, PoiResult> dedup = new java.util.LinkedHashMap<>();
                for (PoiResult p : all) {
                        String k = p.getName().toLowerCase(java.util.Locale.ROOT);
                        dedup.putIfAbsent(k, p);
                }
                List<PoiResult> merged = personalizedPoiSelector.select(
                                new java.util.ArrayList<>(dedup.values()),
                                profile,
                                PersonalizedPoiParams.forUser(userId));
                return new PoiToolExecutionResult(merged, planning);
        }
}
