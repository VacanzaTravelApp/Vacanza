package com.vacanza.backend.service;

import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class RouteSummaryMessageService {

    private static final Set<String> DINING_CATEGORIES = Set.of(
            "restaurant", "cafe", "bar", "fast_food", "bakery", "food", "pub"
    );

    public String buildSummaryMessage(AiChatDto.RouteData routeData, UserProfileForAi profile) {
        if (routeData == null) return null;

        String destination = routeData.getDestination() != null ? routeData.getDestination() : "Rota";
        int days = routeData.getTotalDays() > 0 ? routeData.getTotalDays() : 1;

        List<String> highlights = extractHighlights(routeData);

        if (highlights.isEmpty()) {
            return String.format("%s için %d günlük rotanız hazır. Keyifli gezmeler!", destination, days);
        }

        String highlightText = formatHighlights(highlights);
        return String.format("%s için %d günlük rotanız hazır. %s ve daha fazlası sizi bekliyor. Keyifli gezmeler!",
                destination, days, highlightText);
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

    private String formatHighlights(List<String> highlights) {
        if (highlights.size() == 1) return highlights.get(0);
        if (highlights.size() == 2) return highlights.get(0) + " ve " + highlights.get(1);
        return highlights.get(0) + ", " + highlights.get(1) + " ve " + highlights.get(2);
    }
}
