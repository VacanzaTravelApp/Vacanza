package com.vacanza.backend.service;

import com.vacanza.backend.dto.enums.PoiFeedbackEventType;
import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserRouteFeedback;
import com.vacanza.backend.entity.enums.RouteFeedbackVote;
import com.vacanza.backend.repo.UserRouteFeedbackRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserRouteFeedbackService {

    private final UserRouteFeedbackRepository repository;
    private final AiRouteService aiRouteService;

    @Transactional(readOnly = true)
    public Map<UUID, RouteFeedbackVote> findVotesForUserAndRoutes(UUID userId, Collection<UUID> routeIds) {
        if (routeIds == null || routeIds.isEmpty()) {
            return Map.of();
        }
        List<UUID> distinct = routeIds.stream().distinct().toList();
        List<UserRouteFeedback> rows = repository.findByUser_UserIdAndRoute_RouteIdIn(userId, distinct);
        Map<UUID, RouteFeedbackVote> out = new HashMap<>();
        for (UserRouteFeedback row : rows) {
            out.put(row.getRoute().getRouteId(), row.getVote());
        }
        return out;
    }

    @Transactional
    public void upsertFromThumbs(User user, UUID routeId, PoiFeedbackEventType eventType) {
        if (eventType != PoiFeedbackEventType.THUMBS_UP && eventType != PoiFeedbackEventType.THUMBS_DOWN) {
            throw new IllegalArgumentException("eventType must be THUMBS_UP or THUMBS_DOWN");
        }
        AiRoute route = aiRouteService.getRoute(routeId, user)
                .orElseThrow(() -> new IllegalArgumentException("Route not found or not owned by user"));
        RouteFeedbackVote vote = eventType == PoiFeedbackEventType.THUMBS_UP
                ? RouteFeedbackVote.UP
                : RouteFeedbackVote.DOWN;
        Optional<UserRouteFeedback> existing = repository.findByUser_UserIdAndRoute_RouteId(user.getUserId(), routeId);
        if (existing.isPresent()) {
            UserRouteFeedback e = existing.get();
            e.setVote(vote);
            repository.save(e);
        } else {
            repository.save(UserRouteFeedback.builder()
                    .user(user)
                    .route(route)
                    .vote(vote)
                    .build());
        }
    }
}
