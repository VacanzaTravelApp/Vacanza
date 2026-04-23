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
import com.vacanza.backend.entity.UserPoiFeedback;
import com.vacanza.backend.repo.UserPoiFeedbackRepository;
import com.vacanza.backend.util.PoiDedup;
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
        private final com.vacanza.backend.repo.UserInteractionRepository userInteractionRepository;
        private final UserPoiFeedbackRepository userPoiFeedbackRepository;

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

                // Inject favorited POI names so the AI can prioritize them in routes.
                // Source 1: legacy user_interactions POI_FAVORITE rows.
                // Source 2: thumbs-up rows from UserPoiFeedback (map heart button).
                // Skip entirely when the client opts out via includeFavorites=false.
                boolean includeFavoritesChat = body.getIncludeFavorites() == null || body.getIncludeFavorites();
                if (includeFavoritesChat) {
                        try {
                                List<String> savedPoiNames = collectFavoritePoiNames(user.getUserId());
                                if (!savedPoiNames.isEmpty() && profile != null) {
                                        profile = profile.toBuilder().savedPoiNames(savedPoiNames).build();
                                }
                        } catch (Exception e) {
                                log.warn("Could not fetch saved POI names for user {}: {}", user.getUserId(), e.getMessage());
                        }
                }

                var existingAiPrefs = userPreferenceAiService.getExistingPreferences(user);

                // Inject the latest saved route so the AI service can detect route-edit intent (Turn3).
                // Uses the same __EXISTING_ROUTE__ marker as the polygon-replan flow.
                // Only injected for plain chat messages (not tool results or polygon requests).
                String originalContent = body.getContent();
                AiRoute parentRouteForTurn3 = null;
                if (originalContent != null && !originalContent.contains("__TOOL_RESULT__")) {
                        try {
                                List<AiRoute> existingRoutes = aiRouteService.getRoutesForConversation(user, conversationId);
                                if (!existingRoutes.isEmpty()) {
                                        AiRoute latest = existingRoutes.get(existingRoutes.size() - 1);
                                        String routeJson = latest.getRouteJson();
                                        if (routeJson != null && !routeJson.isBlank()) {
                                                // Strip Java-enriched timeline fields before injection.
                                                // arrival_time_local / departure_time_local / travel_from_previous_min
                                                // are computed by RouteTimelineService after the AI response and are
                                                // not part of the AI schema — they bloat the prompt and output JSON,
                                                // causing truncation at max_tokens when the route is large.
                                                String cleanRouteJson = stripEnrichedTimelineFields(routeJson);
                                                body.setContent(originalContent + "\n__EXISTING_ROUTE__\n" + cleanRouteJson);
                                                parentRouteForTurn3 = latest;
                                        }
                                }
                        } catch (Exception e) {
                                log.warn("Could not inject existing route for conversation {}: {}", conversationId, e.getMessage());
                        }
                }

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

                // Turn3: if the AI edited an existing route (no tool call was made, but route_data is present
                // and we had a parent route), save it as a new version instead of a fresh v1 route.
                boolean isTurn3Response = parentRouteForTurn3 != null
                        && response != null
                        && response.getRouteData() != null
                        && routePlanningWeather == null; // Turn2 always sets routePlanningWeather; Turn3 does not
                if (isTurn3Response) {
                        applyTurn3RouteEnrichmentAndSave(user, conversationId, response, profile,
                                parentRouteForTurn3, originalContent);
                } else {
                        applyRouteEnrichmentAndSave(user, conversationId, response, routePlanningWeather, profile);
                }

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

                boolean includeFavoritesPoly = body.getIncludeFavorites() == null || body.getIncludeFavorites();
                if (includeFavoritesPoly) {
                        try {
                                List<String> savedPoiNames = collectFavoritePoiNames(user.getUserId());
                                if (!savedPoiNames.isEmpty() && profilePoly != null) {
                                        profilePoly = profilePoly.toBuilder().savedPoiNames(savedPoiNames).build();
                                }
                        } catch (Exception e) {
                                log.warn("Could not fetch saved POI names for polygon route (user {}): {}",
                                                user.getUserId(), e.getMessage());
                        }
                }

                PoiToolExecutionResult exec = executePoiSearchForPolygon(
                                ring, categories, totalDays, profilePoly, user.getUserId());

                List<PoiResult> poolWithFavorites = exec.pois();
                if (includeFavoritesPoly) {
                        try {
                                poolWithFavorites = mergeFavoritePoisInsidePolygon(
                                                user.getUserId(), ring, exec.pois());
                        } catch (Exception e) {
                                log.warn("Failed to merge liked POIs into polygon route pool (user {}): {}",
                                                user.getUserId(), e.getMessage());
                        }
                }

                if (poolWithFavorites.size() < MIN_POIS_IN_POLYGON) {
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
                                        .append(objectMapper.writeValueAsString(poolWithFavorites));
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
                                logRouteShape("received_from_ai", response.getRouteData());
                                resolveNullCoordinates(response.getRouteData());
                                stripNullCoordinateWaypoints(response.getRouteData());
                                logRouteShape("after_strip_null", response.getRouteData());
                                if (routePlanningWeather != null && !routePlanningWeather.daily().isEmpty()) {
                                        response.getRouteData().setWeatherForecast(routePlanningWeather.daily());
                                }
                                if (routePlanningWeather != null && !routePlanningWeather.dayParts().isEmpty()) {
                                        response.getRouteData().setWeatherDayParts(routePlanningWeather.dayParts());
                                }
                                routeTimelineService.enrichTimeline(response.getRouteData(), profile);
                                // After enrichTimeline computes real arrival times (including walking legs),
                                // remove any museum/historic stops that ended up at or after 16:45 —
                                // these venues close at 17:00 and the walking overhead pushed them past closing.
                                stripLateClosingVenueStops(response.getRouteData());
                                // If we adjusted any stops (replace/flag), recompute the day timeline once more
                                // so the frontend receives consistent arrival/departure and travel legs.
                                routeTimelineService.enrichTimeline(response.getRouteData(), profile);
                                // Prevent the AI from scheduling the same landmark on multiple days:
                                // keep first occurrence, replace later duplicates where possible.
                                dedupeWaypointsAcrossDays(response.getRouteData());
                                logRouteShape("final", response.getRouteData());
                                UUID savedRouteId = saveRoute(user, conversationId, response.getRouteData());
                                if (savedRouteId != null) {
                                        response.setRouteId(savedRouteId);
                                }
                                String summaryMessage = routeSummaryMessageService.buildSummaryMessage(
                                                response.getRouteData(), profile);
                                if (summaryMessage != null) {
                                        response.setRouteSummaryMessage(summaryMessage);
                                        if (response.getMessageId() != null) {
                                                aiServiceClient.updateMessageContent(conversationId, response.getMessageId(), summaryMessage);
                                        }
                                }
                        }
                } catch (Exception e) {
                        log.warn("Failed to process route data (non-blocking): {}", e.getMessage());
                }
        }

        /**
         * Turn3 variant: enriches the route and saves it as a new version linked to the parent route.
         * Called when the AI edited an existing route via chat (no fresh POI search was performed).
         */
        private void applyTurn3RouteEnrichmentAndSave(
                        User user,
                        UUID conversationId,
                        AiChatDto.MessageSendResponse response,
                        UserProfileForAi profile,
                        AiRoute parentRoute,
                        String userMessage) {
                try {
                        if (response == null || response.getRouteData() == null) return;
                        logRouteShape("turn3_received_from_ai", response.getRouteData());
                        resolveNullCoordinates(response.getRouteData());
                        stripNullCoordinateWaypoints(response.getRouteData());
                        logRouteShape("turn3_after_strip_null", response.getRouteData());
                        routeTimelineService.enrichTimeline(response.getRouteData(), profile);
                        stripLateClosingVenueStops(response.getRouteData());
                        routeTimelineService.enrichTimeline(response.getRouteData(), profile);
                        dedupeWaypointsAcrossDays(response.getRouteData());
                        logRouteShape("turn3_final", response.getRouteData());

                        // Build a short human-readable reason from the user's edit request
                        String reason = "Chat edit";
                        if (userMessage != null && !userMessage.isBlank()) {
                                String trimmed = userMessage.split("\n__EXISTING_ROUTE__")[0].trim();
                                reason = trimmed.length() > 200 ? trimmed.substring(0, 197) + "..." : trimmed;
                        }

                        String routeJson = objectMapper.writeValueAsString(response.getRouteData());
                        AiRoute saved = aiRouteService.saveVersionedRoute(
                                        user, conversationId,
                                        response.getRouteData().getTitle(),
                                        response.getRouteData().getDestination(),
                                        response.getRouteData().getTotalDays(),
                                        routeJson,
                                        parentRoute,
                                        reason);
                        response.setRouteId(saved.getRouteId());

                        String summaryMessage = routeSummaryMessageService.buildSummaryMessage(
                                        response.getRouteData(), profile);
                        if (summaryMessage != null) {
                                response.setRouteSummaryMessage(summaryMessage);
                                if (response.getMessageId() != null) {
                                        aiServiceClient.updateMessageContent(conversationId, response.getMessageId(), summaryMessage);
                                }
                        }
                } catch (Exception e) {
                        log.warn("[TURN3] Failed to save versioned route (non-blocking): {}", e.getMessage());
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
                                                String resultName = result.get().getName();
                                                if (isGeocodingNameCompatible(wp.getName(), resultName)) {
                                                        wp.setLatitude(result.get().getLat());
                                                        wp.setLongitude(result.get().getLon());
                                                        log.info("[RESOLVE NULL] '{}' -> ({}, {}) ✓ (matched '{}')",
                                                                        wp.getName(), result.get().getLat(),
                                                                        result.get().getLon(), resultName);
                                                } else {
                                                        log.warn("[RESOLVE NULL] '{}' geocoded to unrelated '{}' — rejecting to avoid wrong pin",
                                                                        wp.getName(), resultName);
                                                }
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

        /**
         * Removes any waypoints that still have null coordinates after geocoding and renumbers order fields.
         * Prevents frontend from receiving route entries with no map position.
         */
        private void stripNullCoordinateWaypoints(AiChatDto.RouteData routeData) {
                if (routeData == null || routeData.getDays() == null) return;
                String destination = routeData.getDestination();
                DestinationGeocodeResult destGeo = null;
                if (destination != null && !destination.isBlank()) {
                        try {
                                destGeo = mapboxPoiSearchClient.geocodeDestination(destination.trim()).blockOptional().orElse(null);
                        } catch (Exception e) {
                                destGeo = null;
                        }
                }
                for (AiChatDto.DayPlan dayPlan : routeData.getDays()) {
                        if (dayPlan.getWaypoints() == null) continue;
                        int removed = 0;
                        int replaced = 0;

                        java.util.Set<String> existingNames = new java.util.HashSet<>();
                        for (AiChatDto.RouteWaypoint wp : dayPlan.getWaypoints()) {
                                if (wp.getName() != null && !wp.getName().isBlank()) {
                                        existingNames.add(wp.getName().trim().toLowerCase(java.util.Locale.ROOT));
                                }
                        }

                        // Replace null-coordinate waypoints where possible; remove only as a last resort.
                        for (int i = 0; i < dayPlan.getWaypoints().size(); i++) {
                                AiChatDto.RouteWaypoint wp = dayPlan.getWaypoints().get(i);
                                if (wp == null) continue;
                                if (wp.getLatitude() != null && wp.getLongitude() != null) continue;
                                if (wp.getName() == null || wp.getName().isBlank()) continue;

                                PoiResult repl = findNullCoordReplacement(dayPlan.getWaypoints(), i, wp, existingNames, destGeo);
                                if (repl != null) {
                                        String originalName = wp.getName();
                                        existingNames.remove(originalName.trim().toLowerCase(java.util.Locale.ROOT));
                                        wp.setName(repl.getName());
                                        wp.setLatitude(repl.getLat());
                                        wp.setLongitude(repl.getLon());
                                        if (repl.getCategory() != null) {
                                                wp.setCategory(repl.getCategory());
                                        }
                                        wp.setUnavailable(null);
                                        wp.setArrivalTimeLocal(null);
                                        wp.setDepartureTimeLocal(null);
                                        wp.setTravelFromPreviousMin(null);
                                        existingNames.add(wp.getName().trim().toLowerCase(java.util.Locale.ROOT));
                                        replaced++;
                                        log.info("[STRIP NULL] Day {} — '{}' had null coords → replaced with '{}' ({},{})",
                                                dayPlan.getDay(), originalName, repl.getName(), repl.getLat(), repl.getLon());
                                }
                        }

                        int before = dayPlan.getWaypoints().size();
                        dayPlan.getWaypoints().removeIf(wp -> wp == null || wp.getLatitude() == null || wp.getLongitude() == null);
                        removed = before - dayPlan.getWaypoints().size();

                        if (removed > 0 || replaced > 0) {
                                if (removed > 0) {
                                        log.warn("[STRIP NULL] Day {} — removed {} waypoint(s) with no coordinates (after replacement attempts); renumbering",
                                                dayPlan.getDay(), removed);
                                }
                                int order = 1;
                                for (AiChatDto.RouteWaypoint wp : dayPlan.getWaypoints()) {
                                        wp.setOrder(order++);
                                }
                        }
                }
        }

        /**
         * Attempt to replace a null-coordinate waypoint with a nearby POI of a similar category.
         *
         * Strategy:
         * - Anchor search around nearest neighbour waypoint with valid coordinates (prev/next/any in day).
         * - If no neighbour has coordinates, fall back to destination center if available.
         * - Category fallback is tourist_attraction.
         */
        private PoiResult findNullCoordReplacement(
                List<AiChatDto.RouteWaypoint> dayWaypoints,
                int idx,
                AiChatDto.RouteWaypoint missing,
                java.util.Set<String> existingNamesLower,
                DestinationGeocodeResult destGeo) {
                if (missing == null) return null;

                Double anchorLat = null;
                Double anchorLon = null;

                // 1) nearest prev with coords
                for (int j = idx - 1; j >= 0; j--) {
                        AiChatDto.RouteWaypoint w = dayWaypoints.get(j);
                        if (w != null && w.getLatitude() != null && w.getLongitude() != null) {
                                anchorLat = w.getLatitude();
                                anchorLon = w.getLongitude();
                                break;
                        }
                }
                // 2) nearest next with coords
                if (anchorLat == null || anchorLon == null) {
                        for (int j = idx + 1; j < dayWaypoints.size(); j++) {
                                AiChatDto.RouteWaypoint w = dayWaypoints.get(j);
                                if (w != null && w.getLatitude() != null && w.getLongitude() != null) {
                                        anchorLat = w.getLatitude();
                                        anchorLon = w.getLongitude();
                                        break;
                                }
                        }
                }
                // 3) any in day
                if (anchorLat == null || anchorLon == null) {
                        for (AiChatDto.RouteWaypoint w : dayWaypoints) {
                                if (w != null && w.getLatitude() != null && w.getLongitude() != null) {
                                        anchorLat = w.getLatitude();
                                        anchorLon = w.getLongitude();
                                        break;
                                }
                        }
                }
                // 4) destination center
                if ((anchorLat == null || anchorLon == null) && destGeo != null) {
                        anchorLat = destGeo.getCenterLat();
                        anchorLon = destGeo.getCenterLon();
                }
                if (anchorLat == null || anchorLon == null) {
                        return null;
                }

                // ~1.5km-ish bbox.
                double r = 0.014;
                double minLon = anchorLon - r;
                double minLat = anchorLat - r;
                double maxLon = anchorLon + r;
                double maxLat = anchorLat + r;

                String cat = missing.getCategory();
                String category = (cat != null && !cat.isBlank()) ? cat.trim() : "tourist_attraction";

                // Try similar category first, then broaden.
                List<String> cats = List.of(
                        category,
                        "tourist_attraction",
                        "landmark",
                        "monument",
                        "park",
                        "viewpoint",
                        "neighborhood"
                );

                for (String c : cats) {
                        if (c == null || c.isBlank()) continue;
                        List<PoiResult> candidates;
                        try {
                                candidates = mapboxPoiSearchClient
                                        .searchByCategory(c, minLon, minLat, maxLon, maxLat)
                                        .block(java.time.Duration.ofSeconds(4));
                        } catch (Exception e) {
                                candidates = null;
                        }
                        if (candidates == null || candidates.isEmpty()) continue;

                        PoiResult best = null;
                        double bestRating = -1.0;
                        for (PoiResult p : candidates) {
                                if (p == null || p.getName() == null || p.getName().isBlank()) continue;
                                String nameLower = p.getName().trim().toLowerCase(java.util.Locale.ROOT);
                                if (existingNamesLower != null && existingNamesLower.contains(nameLower)) continue;
                                // Avoid obvious self / close-name reuse
                                if (missing.getName() != null) {
                                        String a = missing.getName().trim().toLowerCase(java.util.Locale.ROOT);
                                        String b = p.getName().trim().toLowerCase(java.util.Locale.ROOT);
                                        if (!a.isEmpty() && !b.isEmpty() && (a.contains(b) || b.contains(a))) {
                                                continue;
                                        }
                                }
                                double rating = p.getRating() != null ? p.getRating() : 0.0;
                                if (rating > bestRating) {
                                        bestRating = rating;
                                        best = p;
                                }
                        }
                        if (best != null) {
                                return best;
                        }
                }
                return null;
        }

        /**
         * Deduplicate repeated landmarks across days.
         *
         * We use {@link PoiDedup} token-prefix + proximity to treat sub-features ("parking", "entrance")
         * as the same landmark. First occurrence is kept; later duplicates are replaced with a nearby
         * alternative of similar category around the duplicate's own coordinates. If no replacement is
         * found, the duplicate is removed (last resort).
         */
        private void dedupeWaypointsAcrossDays(AiChatDto.RouteData routeData) {
                if (routeData == null || routeData.getDays() == null) return;
                java.util.List<PoiResult> seen = new java.util.ArrayList<>();

                for (AiChatDto.DayPlan day : routeData.getDays()) {
                        if (day == null || day.getWaypoints() == null || day.getWaypoints().isEmpty()) continue;

                        java.util.Set<String> existingNames = new java.util.HashSet<>();
                        for (AiChatDto.RouteWaypoint wp : day.getWaypoints()) {
                                if (wp != null && wp.getName() != null && !wp.getName().isBlank()) {
                                        existingNames.add(wp.getName().trim().toLowerCase(java.util.Locale.ROOT));
                                }
                        }

                        java.util.List<AiChatDto.RouteWaypoint> toRemove = new java.util.ArrayList<>();

                        for (AiChatDto.RouteWaypoint wp : day.getWaypoints()) {
                                if (wp == null || wp.getName() == null || wp.getName().isBlank()) continue;
                                if (wp.getLatitude() == null || wp.getLongitude() == null) continue;

                                PoiResult asPoi = new PoiResult(wp.getName(), wp.getCategory(), wp.getLatitude(), wp.getLongitude());

                                if (!PoiDedup.isNearDuplicateOfAny(asPoi, seen)) {
                                        seen.add(asPoi);
                                        continue;
                                }

                                PoiResult repl = findDuplicateReplacement(wp, existingNames);
                                if (repl != null) {
                                        String originalName = wp.getName();
                                        existingNames.remove(originalName.trim().toLowerCase(java.util.Locale.ROOT));
                                        wp.setName(repl.getName());
                                        wp.setLatitude(repl.getLat());
                                        wp.setLongitude(repl.getLon());
                                        if (repl.getCategory() != null) {
                                                wp.setCategory(repl.getCategory());
                                        }
                                        wp.setUnavailable(null);
                                        wp.setArrivalTimeLocal(null);
                                        wp.setDepartureTimeLocal(null);
                                        wp.setTravelFromPreviousMin(null);
                                        existingNames.add(wp.getName().trim().toLowerCase(java.util.Locale.ROOT));
                                        log.info("[ROUTE_DEDUP] Day {} — duplicate '{}' → replaced with '{}'",
                                                day.getDay(), originalName, repl.getName());
                                        // Track the replacement as seen so it won't repeat later.
                                        seen.add(new PoiResult(wp.getName(), wp.getCategory(), wp.getLatitude(), wp.getLongitude()));
                                } else {
                                        log.warn("[ROUTE_DEDUP] Day {} — duplicate '{}' removed (no replacement found)",
                                                day.getDay(), wp.getName());
                                        toRemove.add(wp);
                                }
                        }

                        if (!toRemove.isEmpty()) {
                                day.getWaypoints().removeAll(toRemove);
                        }
                        // Keep stable ordering
                        int order = 1;
                        for (AiChatDto.RouteWaypoint wp : day.getWaypoints()) {
                                wp.setOrder(order++);
                        }
                }
        }

        private PoiResult findDuplicateReplacement(
                AiChatDto.RouteWaypoint duplicate,
                java.util.Set<String> existingNamesLower) {
                if (duplicate == null || duplicate.getLatitude() == null || duplicate.getLongitude() == null) {
                        return null;
                }
                double lat = duplicate.getLatitude();
                double lon = duplicate.getLongitude();
                double r = 0.012; // ~1.3km-ish

                String category = (duplicate.getCategory() != null && !duplicate.getCategory().isBlank())
                        ? duplicate.getCategory().trim()
                        : "tourist_attraction";

                // Similar category first, then flexible outdoor categories.
                java.util.List<String> cats = java.util.List.of(
                        category,
                        "tourist_attraction",
                        "landmark",
                        "monument",
                        "park",
                        "viewpoint",
                        "neighborhood"
                );

                for (String c : cats) {
                        if (c == null || c.isBlank()) continue;
                        java.util.List<PoiResult> candidates;
                        try {
                                candidates = mapboxPoiSearchClient
                                        .searchByCategory(c, lon - r, lat - r, lon + r, lat + r)
                                        .block(java.time.Duration.ofSeconds(4));
                        } catch (Exception e) {
                                candidates = null;
                        }
                        if (candidates == null || candidates.isEmpty()) continue;

                        PoiResult best = null;
                        double bestRating = -1.0;
                        for (PoiResult p : candidates) {
                                if (p == null || p.getName() == null || p.getName().isBlank()) continue;
                                String nameLower = p.getName().trim().toLowerCase(java.util.Locale.ROOT);
                                if (existingNamesLower != null && existingNamesLower.contains(nameLower)) continue;
                                if (duplicate.getName() != null) {
                                        String a = duplicate.getName().trim().toLowerCase(java.util.Locale.ROOT);
                                        String b = p.getName().trim().toLowerCase(java.util.Locale.ROOT);
                                        if (!a.isEmpty() && !b.isEmpty() && (a.contains(b) || b.contains(a))) {
                                                continue;
                                        }
                                }
                                double rating = p.getRating() != null ? p.getRating() : 0.0;
                                if (rating > bestRating) {
                                        bestRating = rating;
                                        best = p;
                                }
                        }
                        if (best != null) return best;
                }
                return null;
        }

        /**
         * Returns true if the geocoding result name is reasonably related to the searched place name.
         * Prevents wrong pins when Mapbox returns an unrelated POI (e.g. a restaurant instead of a bridge).
         * Uses word-level overlap: at least one significant word (>3 chars) must be shared.
         */
        private static boolean isGeocodingNameCompatible(String queryName, String resultName) {
                // Reject if either side is missing — don't silently accept unknown results
                if (queryName == null || resultName == null) return false;
                String q = queryName.toLowerCase(Locale.ROOT);
                String r = resultName.toLowerCase(Locale.ROOT);
                // Direct containment (handles "Golden Gate Bridge" ⊂ "Golden Gate Bridge, Presidio…")
                if (r.contains(q) || q.contains(r)) return true;
                // Compact containment: strip spaces/punctuation then compare.
                // Handles compound-word vs spaced variants: "Göbeklitepe" ↔ "Göbekli Tepe",
                // "Atatürkmausoleum" ↔ "Atatürk Mausoleum", etc.
                String qCompact = q.replaceAll("[\\s,\\-/.']+", "");
                String rCompact = r.replaceAll("[\\s,\\-/.']+", "");
                if (qCompact.length() > 4 && (rCompact.contains(qCompact) || qCompact.contains(rCompact))) return true;
                // Word-level overlap — count significant words (>4 chars) that match exactly.
                // Prefix matching is intentionally disabled: "Bosphorus Bridge" vs "Bosphorus Strait"
                // share the prefix "Bosphor" but are completely different places.
                // Threshold: queries with 2+ significant words require AT LEAST 2 matches to avoid
                // false positives like "Galata Tower" → "Galata Port" (only "galata" would match).
                String[] qWords = q.split("[\\s,\\-/]+");
                String[] rWords = r.split("[\\s,\\-/]+");
                java.util.List<String> qSig = new java.util.ArrayList<>();
                for (String w : qWords) { if (w.length() > 4) qSig.add(w); }
                if (qSig.isEmpty()) return false;
                int required = qSig.size() >= 2 ? 2 : 1;
                int matched = 0;
                for (String qw : qSig) {
                        for (String rw : rWords) {
                                if (rw.length() <= 4) continue;
                                if (qw.equals(rw)) { matched++; break; }
                        }
                        if (matched >= required) return true;
                }
                return false;
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

                // Resolve each must_visit landmark via the full resolvePlace strategy (suggest+retrieve,
                // expanded bbox, geocoding v5 fallbacks) and validate name compatibility before accepting.
                // Previously used forwardSearchPoi (limit=3, no name check) which blindly added all results
                // including wrong POIs that could override correct category-search coordinates.
                List<PoiResult> mustVisitPois = new java.util.ArrayList<>();
                if (mustVisit != null) {
                        for (String placeName : mustVisit) {
                                if (placeName == null || placeName.isBlank()) continue;
                                var result = mapboxPoiSearchClient.resolvePlace(
                                                placeName, destination,
                                                dest.getMinLon(), dest.getMinLat(), dest.getMaxLon(), dest.getMaxLat())
                                        .blockOptional();
                                if (result.isPresent()) {
                                        if (isGeocodingNameCompatible(placeName, result.get().getName())) {
                                                mustVisitPois.add(result.get());
                                                log.info("[MUST_VISIT] '{}' → ({}, {}) matched '{}'",
                                                        placeName, result.get().getLat(), result.get().getLon(),
                                                        result.get().getName());
                                        } else {
                                                log.warn("[MUST_VISIT] '{}' geocoded to unrelated '{}' — rejecting to avoid wrong pin",
                                                        placeName, result.get().getName());
                                        }
                                } else {
                                        log.warn("[MUST_VISIT] '{}' — all resolution strategies exhausted", placeName);
                                }
                        }
                }

                // Dedup: first pass — category-search results (putIfAbsent keeps first occurrence)
                java.util.Map<String, PoiResult> dedup = new java.util.LinkedHashMap<>();
                for (PoiResult p : all) {
                        if (p == null || p.getName() == null || p.getName().isBlank()) continue;
                        String k = p.getName().toLowerCase(java.util.Locale.ROOT);
                        dedup.putIfAbsent(k, p);
                }
                // Second pass — must-visit results OVERRIDE category-search versions.
                // This ensures the AI gets the highest-confidence coordinates for landmark entries.
                for (PoiResult p : mustVisitPois) {
                        if (p == null || p.getName() == null || p.getName().isBlank()) continue;
                        String k = p.getName().toLowerCase(java.util.Locale.ROOT);
                        dedup.put(k, p);  // force override
                }
                // Collapse Mapbox sub-features ("Anıtkabir" + "Anıtkabir güvenlik" etc.) before the AI sees them.
                int beforeCollapse = dedup.size();
                List<PoiResult> collapsed = PoiDedup.collapseNearDuplicates(
                                new java.util.ArrayList<>(dedup.values()));
                if (collapsed.size() < beforeCollapse) {
                        log.info("[POI_DEDUP] chat: collapsed {} near-duplicate sub-feature(s)",
                                        beforeCollapse - collapsed.size());
                }
                List<PoiResult> merged = personalizedPoiSelector.select(
                                collapsed,
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

        /**
         * Remove Java-enriched timeline fields from a saved route JSON before injecting it
         * into the Turn3 prompt.  These fields (arrival_time_local, departure_time_local,
         * travel_from_previous_min, day_end_local) are added by {@link RouteTimelineService}
         * after the AI response and are NOT part of the AI's output schema.  Including them
         * in the prompt causes the AI to echo them back, roughly doubling waypoint JSON size
         * and hitting the max_tokens limit for 3-day+ routes.
         *
         * Uses simple regex replacement so no full JSON round-trip is needed; the fields are
         * always scalar (string or int/null) so there is no nesting risk.
         */
        private static String stripEnrichedTimelineFields(String routeJson) {
                if (routeJson == null) return null;
                // Remove: "field_name":"value" or "field_name":null or "field_name":123
                // Fields to strip: arrival_time_local, departure_time_local, travel_from_previous_min, day_end_local
                return routeJson
                        .replaceAll(",?\\s*\"arrival_time_local\"\\s*:\\s*(\"[^\"]*\"|null)", "")
                        .replaceAll(",?\\s*\"departure_time_local\"\\s*:\\s*(\"[^\"]*\"|null)", "")
                        .replaceAll(",?\\s*\"travel_from_previous_min\"\\s*:\\s*(\\d+|null)", "")
                        .replaceAll(",?\\s*\"day_end_local\"\\s*:\\s*(\"[^\"]*\"|null)", "");
        }

        /**
         * Categories that have a hard closing time around 17:00.
         * Outdoor landmarks (bridges, squares, viewpoints) are intentionally excluded —
         * they can be visited at any hour.
         */
        private static final java.util.Set<String> EARLY_CLOSE_CATS = java.util.Set.of(
                "museum", "art_gallery", "palace", "historic_site", "ruins",
                "church", "mosque", "castle", "aquarium", "zoo"
        );

        /**
         * Latest acceptable arrival at a venue that closes at 17:00.
         * 16:45 gives the visitor 15 minutes inside — anything later is not worth visiting.
         * Walking time is already baked into the computed arrival (enrichTimeline adds real Mapbox durations),
         * so this check uses the final realistic time rather than the AI's naive estimate.
         */
        private static final java.time.LocalTime VENUE_LATEST_ARRIVAL =
                java.time.LocalTime.of(16, 45);

        private static final java.time.format.DateTimeFormatter HH_MM_FMT =
                java.time.format.DateTimeFormatter.ofPattern("HH:mm");

        /**
         * Remove museum/historic stops whose computed arrival time (set by {@link RouteTimelineService})
         * is at or after {@link #VENUE_LATEST_ARRIVAL}.  Walking overhead between stops means the AI's
         * naive schedule often pushes evening sightseeing past closing — this is the authoritative fix
         * because it runs after real walking durations are known.
         */
        private void stripLateClosingVenueStops(AiChatDto.RouteData routeData) {
                if (routeData == null || routeData.getDays() == null) return;
                for (AiChatDto.DayPlan day : routeData.getDays()) {
                        if (day.getWaypoints() == null) continue;
                        int lateCount = 0;
                        java.util.Set<String> existingNames = new java.util.HashSet<>();
                        for (AiChatDto.RouteWaypoint wp : day.getWaypoints()) {
                                if (wp.getName() != null && !wp.getName().isBlank()) {
                                        existingNames.add(wp.getName().trim().toLowerCase(java.util.Locale.ROOT));
                                }
                        }

                        for (AiChatDto.RouteWaypoint wp : day.getWaypoints()) {
                                String cat = wp.getCategory() == null
                                        ? "" : wp.getCategory().trim().toLowerCase(java.util.Locale.ROOT);
                                if (!EARLY_CLOSE_CATS.contains(cat)) continue;
                                String arrival = wp.getArrivalTimeLocal();
                                if (arrival == null || arrival.isBlank()) continue;
                                java.time.LocalTime t;
                                try {
                                        t = java.time.LocalTime.parse(arrival.trim(), HH_MM_FMT);
                                } catch (Exception e) {
                                        continue; // can't parse → keep safe
                                }
                                if (t.isBefore(VENUE_LATEST_ARRIVAL)) continue;

                                lateCount++;

                                // Instead of removing the stop and leaving a "hole" in the day, try to replace it
                                // with an outdoor/anytime-stop nearby (viewpoint/park/neighborhood/etc.).
                                PoiResult replacement = findLateVenueReplacement(wp, existingNames);
                                if (replacement != null) {
                                        String originalName = wp.getName();
                                        existingNames.remove(originalName == null ? "" : originalName.trim().toLowerCase(java.util.Locale.ROOT));
                                        wp.setName(replacement.getName());
                                        wp.setLatitude(replacement.getLat());
                                        wp.setLongitude(replacement.getLon());
                                        if (replacement.getCategory() != null) {
                                                wp.setCategory(replacement.getCategory());
                                        }
                                        wp.setUnavailable(null);
                                        wp.setArrivalTimeLocal(null);
                                        wp.setDepartureTimeLocal(null);
                                        wp.setTravelFromPreviousMin(null);
                                        if (wp.getName() != null) {
                                                existingNames.add(wp.getName().trim().toLowerCase(java.util.Locale.ROOT));
                                        }
                                        log.info("[TIMELINE] Day {}: '{}' arrived at {} (late) → replaced with '{}'",
                                                day.getDay(), originalName, arrival.trim(), replacement.getName());
                                } else {
                                        // Fallback: keep it but flag unavailable so the user sees why the day is sparse.
                                        wp.setUnavailable(true);
                                        log.warn("[TIMELINE] Day {}: '{}' arrived at {} (late) — no replacement found, marked unavailable",
                                                day.getDay(), wp.getName(), arrival.trim());
                                }
                        }

                        if (lateCount > 0) {
                                // Keep stable ordering in the list after replacements.
                                int order = 1;
                                for (AiChatDto.RouteWaypoint wp : day.getWaypoints()) {
                                        wp.setOrder(order++);
                                }
                        }
                }
        }

        /**
         * Find a nearby replacement for a late-closing venue stop.
         * We intentionally avoid early-closing categories and prefer "anytime" stops.
         */
        private PoiResult findLateVenueReplacement(
                AiChatDto.RouteWaypoint wp,
                java.util.Set<String> existingNamesLower) {
                if (wp == null || wp.getLatitude() == null || wp.getLongitude() == null) {
                        return null;
                }
                double lat = wp.getLatitude();
                double lon = wp.getLongitude();
                double r = 0.012; // ~1.3km-ish

                // Priority order: outdoor / flexible categories first.
                List<String> cats = List.of(
                        "viewpoint",
                        "park",
                        "neighborhood",
                        "landmark",
                        "tourist_attraction",
                        "monument"
                );

                for (String c : cats) {
                        try {
                                List<PoiResult> candidates = mapboxPoiSearchClient
                                        .searchByCategory(c, lon - r, lat - r, lon + r, lat + r)
                                        .block(java.time.Duration.ofSeconds(4));
                                if (candidates == null || candidates.isEmpty()) {
                                        continue;
                                }
                                PoiResult best = null;
                                double bestRating = -1.0;
                                for (PoiResult p : candidates) {
                                        if (p == null || p.getName() == null || p.getName().isBlank()) continue;
                                        String nameLower = p.getName().trim().toLowerCase(java.util.Locale.ROOT);
                                        if (existingNamesLower != null && existingNamesLower.contains(nameLower)) continue;
                                        if (wp.getName() != null) {
                                                String a = wp.getName().trim().toLowerCase(java.util.Locale.ROOT);
                                                String b = p.getName().trim().toLowerCase(java.util.Locale.ROOT);
                                                if (!a.isEmpty() && !b.isEmpty() && (a.contains(b) || b.contains(a))) {
                                                        continue;
                                                }
                                        }
                                        // Avoid swapping late museum with another early-closing venue.
                                        if (p.getCategory() != null) {
                                                String pc = p.getCategory().trim().toLowerCase(java.util.Locale.ROOT);
                                                if (EARLY_CLOSE_CATS.contains(pc)) continue;
                                        }
                                        double rating = p.getRating() != null ? p.getRating() : 0.0;
                                        if (rating > bestRating) {
                                                bestRating = rating;
                                                best = p;
                                        }
                                }
                                if (best != null) {
                                        return best;
                                }
                        } catch (Exception e) {
                                // Non-blocking: just try the next category.
                                log.debug("[TIMELINE] Replacement search failed for cat={} name='{}': {}",
                                        c, wp.getName(), e.getMessage());
                        }
                }
                return null;
        }

        /**
         * Emits a single-line summary of per-day waypoint counts. Called at each stage of the
         * enrichment pipeline so we can tell whether short days (3 POIs/day) come from the AI
         * itself or from a downstream strip step.
         */
        private static void logRouteShape(String tag, AiChatDto.RouteData routeData) {
                if (routeData == null || routeData.getDays() == null || routeData.getDays().isEmpty()) {
                        log.info("[ROUTE_SHAPE] {}: <no days>", tag);
                        return;
                }
                StringBuilder sb = new StringBuilder();
                int total = 0;
                for (AiChatDto.DayPlan day : routeData.getDays()) {
                        int n = day.getWaypoints() == null ? 0 : day.getWaypoints().size();
                        total += n;
                        if (sb.length() > 0) sb.append(", ");
                        sb.append("day").append(day.getDay()).append('=').append(n);
                }
                log.info("[ROUTE_SHAPE] {}: {} (total={})", tag, sb, total);
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
                int beforeCollapse = dedup.size();
                List<PoiResult> collapsed = PoiDedup.collapseNearDuplicates(
                                new java.util.ArrayList<>(dedup.values()));
                if (collapsed.size() < beforeCollapse) {
                        log.info("[POI_DEDUP] polygon: collapsed {} near-duplicate sub-feature(s)",
                                        beforeCollapse - collapsed.size());
                }
                List<PoiResult> merged = personalizedPoiSelector.select(
                                collapsed,
                                profile,
                                PersonalizedPoiParams.forUser(userId));

                long sightCount = merged.stream().filter(p -> !DINING_CATS.contains(
                                (p.getCategory() == null ? "" : p.getCategory()).toLowerCase(java.util.Locale.ROOT))).count();
                long diningCount = merged.size() - sightCount;
                log.info("[POI_POOL] polygon total={} (sight={} dining={})",
                                merged.size(), sightCount, diningCount);
                for (PoiResult p : merged) {
                        log.info("[POI_POOL]   [{}] {} → lat:{} lon:{}",
                                        p.getCategory(), p.getName(), p.getLat(), p.getLon());
                }

                return new PoiToolExecutionResult(merged, planning);
        }

        /**
         * Merges legacy {@code user_interactions POI_FAVORITE} names with thumbs-up POIs from
         * {@link UserPoiFeedback} so the AI profile gets a single de-duplicated "liked places" list.
         */
        private List<String> collectFavoritePoiNames(UUID userId) {
                java.util.LinkedHashSet<String> names = new java.util.LinkedHashSet<>();
                try {
                        List<String> legacy = userInteractionRepository.findFavoritePoiNamesByUserId(userId);
                        if (legacy != null) {
                                for (String n : legacy) {
                                        if (n != null && !n.isBlank()) {
                                                names.add(n.trim());
                                        }
                                }
                        }
                } catch (Exception e) {
                        log.debug("legacy POI_FAVORITE fetch failed for user {}: {}", userId, e.getMessage());
                }
                try {
                        List<UserPoiFeedback> thumbsUp = userPoiFeedbackRepository
                                        .findByUser_UserIdAndScoreGreaterThan(userId, 0.0);
                        if (thumbsUp != null) {
                                for (UserPoiFeedback fb : thumbsUp) {
                                        String n = fb.getPoiName();
                                        if (n != null && !n.isBlank()) {
                                                names.add(n.trim());
                                        }
                                }
                        }
                } catch (Exception e) {
                        log.debug("thumbs-up POI fetch failed for user {}: {}", userId, e.getMessage());
                }
                return new java.util.ArrayList<>(names);
        }

        /**
         * Adds the user's liked POIs (thumbs-up with known coordinates) that fall inside {@code ring}
         * to {@code existing}. Uses {@link PoiDedup#isNearDuplicateOfAny} so a thumbs-up on
         * "Anıtkabir" doesn't append next to a Mapbox "Anıtkabir güvenlik" entry already in the pool.
         */
        private List<PoiResult> mergeFavoritePoisInsidePolygon(
                        UUID userId, List<double[]> ring, List<PoiResult> existing) {
                List<PoiResult> out = new java.util.ArrayList<>(existing);
                List<UserPoiFeedback> thumbsUp = userPoiFeedbackRepository
                                .findByUser_UserIdAndScoreGreaterThan(userId, 0.0);
                if (thumbsUp == null || thumbsUp.isEmpty()) {
                        return out;
                }
                int added = 0;
                for (UserPoiFeedback fb : thumbsUp) {
                        Double lat = fb.getPoiLatitude();
                        Double lon = fb.getPoiLongitude();
                        String name = fb.getPoiName();
                        if (lat == null || lon == null || name == null || name.isBlank()) {
                                continue;
                        }
                        if (!PolygonRouteGeometry.pointInPolygon(lon, lat, ring)) {
                                continue;
                        }
                        PoiResult pr = new PoiResult(name.trim(), fb.getPoiCategory(), lat, lon);
                        if (PoiDedup.isNearDuplicateOfAny(pr, out)) {
                                continue;
                        }
                        out.add(pr);
                        added++;
                }
                if (added > 0) {
                        log.info("Polygon route: merged {} liked POI(s) for user {}", added, userId);
                }
                return out;
        }
}
