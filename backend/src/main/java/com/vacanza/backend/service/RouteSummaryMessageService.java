package com.vacanza.backend.service;

import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Builds a short, user-facing message that explains the generated route
 * (e.g. "Müzeleri sevdiğini biliyordum, o yüzden rotanda ağırlıklı olarak müzeler var.").
 */
@Service
public class RouteSummaryMessageService {

    private static final Map<String, String> CATEGORY_TO_TURKISH = Map.ofEntries(
            Map.entry("museum", "müzeler"),
            Map.entry("museums", "müzeler"),
            Map.entry("cafe", "kafeler"),
            Map.entry("cafes", "kafeler"),
            Map.entry("park", "parklar"),
            Map.entry("parks", "parklar"),
            Map.entry("restaurant", "restoranlar"),
            Map.entry("restaurants", "restoranlar"),
            Map.entry("monument", "anıtlar"),
            Map.entry("monuments", "anıtlar"),
            Map.entry("attraction", "turistik noktalar"),
            Map.entry("attractions", "turistik noktalar")
    );

    /**
     * Returns a 1–2 sentence message about the route, optionally referencing user preferences.
     */
    public String buildSummaryMessage(AiChatDto.RouteData routeData, UserProfileForAi profile) {
        if (routeData == null) return null;

        Set<String> routeCategories = collectCategoriesFromRoute(routeData);
        if (routeCategories.isEmpty()) {
            return String.format("%s için %d günlük planın hazır. Haritada görmek için aşağıdaki butona tıkla. Keyifli gezmeler!",
                    routeData.getDestination() != null ? routeData.getDestination() : "Rota",
                    routeData.getTotalDays() > 0 ? routeData.getTotalDays() : 1);
        }

        List<String> favMatches = new ArrayList<>();
        if (profile != null && profile.getFavoriteCategories() != null && !profile.getFavoriteCategories().isEmpty()) {
            Set<String> favLower = profile.getFavoriteCategories().stream()
                    .filter(Objects::nonNull)
                    .map(s -> s.trim().toLowerCase(Locale.ROOT))
                    .filter(s -> !s.isEmpty())
                    .collect(Collectors.toSet());
            for (String cat : routeCategories) {
                String c = cat.toLowerCase(Locale.ROOT);
                if (favLower.contains(c) || favLower.stream().anyMatch(f -> c.contains(f) || f.contains(c))) {
                    favMatches.add(toTurkishLabel(cat));
                }
            }
        }

        String categoryPhrase = routeCategories.stream()
                .map(this::toTurkishLabel)
                .distinct()
                .collect(Collectors.joining(", "));

        if (!favMatches.isEmpty()) {
            String matchWord = favMatches.get(0);
            return String.format("Senin %s sevdiğini biliyordum, o yüzden rotanda ağırlıklı olarak %s var. Keyifli gezmeler!",
                    matchWord, matchWord);
        }

        return String.format("%s için %d günlük planın hazır. Rotanda %s var. Haritada görmek için aşağıdaki butona tıkla. Keyifli gezmeler!",
                routeData.getDestination() != null ? routeData.getDestination() : "Rota",
                routeData.getTotalDays() > 0 ? routeData.getTotalDays() : 1,
                categoryPhrase);
    }

    private Set<String> collectCategoriesFromRoute(AiChatDto.RouteData routeData) {
        Set<String> set = new LinkedHashSet<>();
        if (routeData.getDays() == null) return set;
        for (AiChatDto.DayPlan day : routeData.getDays()) {
            if (day.getWaypoints() == null) continue;
            for (AiChatDto.RouteWaypoint wp : day.getWaypoints()) {
                if (wp.getCategory() != null && !wp.getCategory().isBlank()) {
                    set.add(wp.getCategory().trim());
                }
            }
        }
        return set;
    }

    private String toTurkishLabel(String category) {
        if (category == null || category.isBlank()) return "yerler";
        String key = category.trim().toLowerCase(Locale.ROOT);
        return CATEGORY_TO_TURKISH.getOrDefault(key, category);
    }
}
