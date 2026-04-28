package com.vacanza.backend.service;

import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class RouteSummaryMessageService {

    private static final Set<String> DINING_CATEGORIES = Set.of(
            "restaurant", "cafe", "bar", "fast_food", "bakery", "food", "pub"
    );

    /** Letters typical of Turkish (and not of a plain-ASCII English request). */
    private static final Pattern TURKISH_SPECIFIC_LETTERS = Pattern.compile("[çğıöşüÇĞİÖŞÜ]");

    /** English phrasing common in travel requests (user message is ASCII). */
    private static final Pattern ENGLISH_ITINERARY_CUES = Pattern.compile(
            "(?i)\\b(day|days|route|routes|trip|trips|plan|plans|itinerary|vacation|holiday|explore|visit)\\b"
    );

    /** Turkish words strongly suggesting a Turkish message. */
    private static final Pattern TURKISH_ITINERARY_CUES = Pattern.compile(
            "(?i)\\b(gün|günlük|rota|tatil|için|gezi|şehir|bana|öner|gezme|keyif)\\b"
    );

    public String buildSummaryMessage(AiChatDto.RouteData routeData, UserProfileForAi profile) {
        return buildSummaryMessage(routeData, profile, null);
    }

    /**
     * Short bubble shown when a route is ready. Language follows the triggering user message when
     * detectable, else {@link UserProfileForAi#getPreferredLanguage()}, else Turkish (legacy default).
     *
     * @param userLocaleHint raw user text (e.g. chat message before route); may be null for map-only flows
     */
    public String buildSummaryMessage(
            AiChatDto.RouteData routeData,
            UserProfileForAi profile,
            String userLocaleHint) {
        if (routeData == null) return null;

        String destination = routeData.getDestination() != null ? routeData.getDestination() : "Rota";
        int days = routeData.getTotalDays() > 0 ? routeData.getTotalDays() : 1;

        List<String> highlights = extractHighlights(routeData);
        boolean turkish = preferTurkishSummary(userLocaleHint, profile);

        if (highlights.isEmpty()) {
            return turkish
                    ? String.format("%s için %d günlük rotanız hazır. Keyifli gezmeler!", destination, days)
                    : String.format(
                            "Your %d-day itinerary for %s is ready. Enjoy your trip!",
                            days, destination);
        }

        String highlightText = formatHighlights(highlights, turkish);
        return turkish
                ? String.format(
                        "%s için %d günlük rotanız hazır. %s ve daha fazlası sizi bekliyor. Keyifli gezmeler!",
                        destination, days, highlightText)
                : String.format(
                        "Your %d-day itinerary for %s is ready. %s and more await you. Enjoy your trip!",
                        days, destination, highlightText);
    }

    private boolean preferTurkishSummary(String userLocaleHint, UserProfileForAi profile) {
        String sample = normalizeLocaleHint(userLocaleHint);
        if (!sample.isBlank()) {
            if (TURKISH_SPECIFIC_LETTERS.matcher(sample).find() || TURKISH_ITINERARY_CUES.matcher(sample).find()) {
                return true;
            }
            if (ENGLISH_ITINERARY_CUES.matcher(sample).find()) {
                return false;
            }
        }
        if (profile != null && profile.getPreferredLanguage() != null) {
            String pl = profile.getPreferredLanguage().trim().toLowerCase(Locale.ROOT);
            if (pl.startsWith("en")) {
                return false;
            }
            if (pl.startsWith("tr")) {
                return true;
            }
        }
        return true;
    }

    /**
     * Use only the human-written part of the message (drop injected route JSON / tool payloads).
     */
    private static String normalizeLocaleHint(String raw) {
        if (raw == null) return "";
        String s = raw;
        int existing = s.indexOf("\n__EXISTING_ROUTE__");
        if (existing != -1) {
            s = s.substring(0, existing);
        }
        int tool = s.indexOf("__TOOL_RESULT__");
        if (tool != -1) {
            s = s.substring(0, tool);
        }
        s = s.trim();
        // Drop bracketed single-line prefixes from map flows
        if (s.startsWith("[Polygon route request]") || s.startsWith("[Replan day request]")) {
            int nl = s.indexOf('\n');
            s = nl == -1 ? "" : s.substring(nl + 1).trim();
        }
        // If all that's left is JSON, skip (no natural language)
        if (s.startsWith("{") && s.contains("\"tool\"")) {
            return "";
        }
        return s.trim();
    }

    private List<String> extractHighlights(AiChatDto.RouteData routeData) {
        if (routeData.getDays() == null || routeData.getDays().isEmpty()) return List.of();

        return routeData.getDays().stream()
                .limit(2)
                .flatMap(day -> day.getWaypoints() == null ? java.util.stream.Stream.empty()
                        : day.getWaypoints().stream())
                .filter(wp -> wp.getName() != null && !wp.getName().isBlank())
                .filter(wp -> !isDining(wp.getCategory()))
                .map(wp -> wp.getName().trim())
                .distinct()
                .limit(3)
                .collect(Collectors.toList());
    }

    private boolean isDining(String category) {
        if (category == null) return false;
        return DINING_CATEGORIES.contains(category.toLowerCase(Locale.ROOT));
    }

    private String formatHighlights(List<String> highlights, boolean turkish) {
        if (turkish) {
            if (highlights.size() == 1) return highlights.get(0);
            if (highlights.size() == 2) return highlights.get(0) + " ve " + highlights.get(1);
            return highlights.get(0) + ", " + highlights.get(1) + " ve " + highlights.get(2);
        }
        if (highlights.size() == 1) return highlights.get(0);
        if (highlights.size() == 2) return highlights.get(0) + " and " + highlights.get(1);
        return highlights.get(0) + ", " + highlights.get(1) + ", and " + highlights.get(2);
    }
}
