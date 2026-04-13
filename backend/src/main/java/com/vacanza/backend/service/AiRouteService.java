package com.vacanza.backend.service;

import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.repo.AiRouteRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AiRouteService {

    private final AiRouteRepository repository;

    @Transactional
    public AiRoute saveRoute(User user, UUID conversationId, String title,
                             String destination, int totalDays, String routeJson) {
        AiRoute route = AiRoute.builder()
                .user(user)
                .conversationId(conversationId)
                .title(title)
                .destination(destination)
                .totalDays(totalDays)
                .routeJson(routeJson)
                .build();
        AiRoute saved = repository.save(route);
        log.info("Saved AI route '{}' for user {}", title, user.getUserId());
        return saved;
    }

    @Transactional(readOnly = true)
    public List<AiRoute> getUserRoutes(User user) {
        return repository.findByUserOrderByGeneratedAtDesc(user);
    }

    @Transactional(readOnly = true)
    public Optional<AiRoute> getRoute(UUID routeId, User user) {
        return repository.findByRouteIdAndUser(routeId, user);
    }

    @Transactional(readOnly = true)
    public List<AiRoute> getRoutesForConversation(User user, UUID conversationId) {
        return repository.findByUserAndConversationIdOrderByGeneratedAtAsc(user, conversationId);
    }

    /**
     * Save a new versioned route derived from a parent (e.g. Turn3 chat edit).
     * Increments version by 1 and links parentRouteId so the full edit history is preserved.
     */
    @Transactional
    public AiRoute saveVersionedRoute(User user, UUID conversationId, String title,
                                      String destination, int totalDays, String routeJson,
                                      AiRoute parent, String adjustmentReason) {
        AiRoute route = AiRoute.builder()
                .user(user)
                .conversationId(conversationId)
                .title(title)
                .destination(destination)
                .totalDays(totalDays)
                .routeJson(routeJson)
                .version(parent.getVersion() + 1)
                .parentRouteId(parent.getRouteId())
                .adjustedAt(LocalDateTime.now())
                .adjustmentReason(adjustmentReason)
                .build();
        AiRoute saved = repository.save(route);
        log.info("Saved versioned AI route '{}' v{} (parent={}) for user {}",
                title, saved.getVersion(), parent.getRouteId(), user.getUserId());
        return saved;
    }

    @Transactional
    public void deleteRoute(UUID routeId, User user) {
        repository.findByRouteIdAndUser(routeId, user)
                .ifPresent(route -> {
                    repository.delete(route);
                    log.info("Deleted AI route {} for user {}", routeId, user.getUserId());
                });
    }
}
