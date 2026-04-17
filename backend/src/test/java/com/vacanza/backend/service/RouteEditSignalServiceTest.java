package com.vacanza.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserInteraction;
import com.vacanza.backend.entity.enums.InteractionType;
import com.vacanza.backend.repo.UserInteractionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class RouteEditSignalServiceTest {

    private UserInteractionRepository interactionRepo;
    private BehaviorAnalysisService behaviorAnalysisService;
    private RouteEditSignalService service;

    private User user;

    @BeforeEach
    void setUp() {
        interactionRepo = mock(UserInteractionRepository.class);
        behaviorAnalysisService = mock(BehaviorAnalysisService.class);
        service = new RouteEditSignalService(new ObjectMapper(), interactionRepo, behaviorAnalysisService);

        user = new User();
        user.setUserId(UUID.randomUUID());
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    private AiRoute routeWith(String json, String destination, int version, UUID parentId) {
        AiRoute r = new AiRoute();
        r.setRouteId(UUID.randomUUID());
        r.setRouteJson(json);
        r.setDestination(destination);
        r.setVersion(version);
        r.setParentRouteId(parentId);
        return r;
    }

    private String routeJson(String... categoriesPerWaypoint) {
        StringBuilder wps = new StringBuilder();
        for (String cat : categoriesPerWaypoint) {
            if (wps.length() > 0) wps.append(",");
            wps.append("{\"name\":\"place\",\"category\":\"").append(cat).append("\"}");
        }
        return "{\"days\":[{\"waypoints\":[" + wps + "]}]}";
    }

    // ── tests ─────────────────────────────────────────────────────────────────

    @Test
    void removes_generate_ROUTE_EDIT_REMOVE_signals() {
        // Parent: 3 museums. New: 0 museums → 3x REMOVE
        AiRoute parent = routeWith(routeJson("museum", "museum", "museum"), "Istanbul", 1, null);
        AiRoute newRoute = routeWith(routeJson("restaurant"), "Istanbul", 2, parent.getRouteId());

        service.processEditSignals(user, parent, newRoute);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<UserInteraction>> captor = ArgumentCaptor.forClass(List.class);
        verify(interactionRepo).saveAll(captor.capture());

        List<UserInteraction> saved = captor.getValue();
        long removes = saved.stream()
                .filter(i -> i.getInteractionType() == InteractionType.ROUTE_EDIT_REMOVE
                          && "museum".equals(i.getMetadata().get("category")))
                .count();
        assertThat(removes).isEqualTo(3);
    }

    @Test
    void adds_generate_ROUTE_EDIT_ADD_signals() {
        // Parent: 1 restaurant. New: 4 restaurants → 3x ADD
        AiRoute parent = routeWith(routeJson("restaurant"), "Ankara", 1, null);
        AiRoute newRoute = routeWith(routeJson("restaurant", "restaurant", "restaurant", "restaurant"),
                "Ankara", 2, parent.getRouteId());

        service.processEditSignals(user, parent, newRoute);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<UserInteraction>> captor = ArgumentCaptor.forClass(List.class);
        verify(interactionRepo).saveAll(captor.capture());

        long adds = captor.getValue().stream()
                .filter(i -> i.getInteractionType() == InteractionType.ROUTE_EDIT_ADD
                          && "restaurant".equals(i.getMetadata().get("category")))
                .count();
        assertThat(adds).isEqualTo(3);
    }

    @Test
    void destination_is_stored_in_metadata_and_normalised_to_lowercase() {
        AiRoute parent = routeWith(routeJson("museum", "museum"), "İSTANBUL", 1, null);
        AiRoute newRoute = routeWith(routeJson("cafe"), "İSTANBUL", 2, parent.getRouteId());

        service.processEditSignals(user, parent, newRoute);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<UserInteraction>> captor = ArgumentCaptor.forClass(List.class);
        verify(interactionRepo).saveAll(captor.capture());

        captor.getValue().forEach(interaction ->
                assertThat(interaction.getMetadata().get("destination")).isEqualTo("i̇stanbul"));
    }

    @Test
    void unchanged_categories_produce_no_signals() {
        // Same category counts in both routes → no signals
        AiRoute parent  = routeWith(routeJson("museum", "restaurant"), "Paris", 1, null);
        AiRoute newRoute = routeWith(routeJson("museum", "restaurant"), "Paris", 2, parent.getRouteId());

        service.processEditSignals(user, parent, newRoute);

        verify(interactionRepo, never()).saveAll(any());
    }

    @Test
    void both_global_and_destination_analysis_are_triggered() {
        AiRoute parent  = routeWith(routeJson("museum"), "Rome", 1, null);
        AiRoute newRoute = routeWith(routeJson("nature"), "Rome", 2, parent.getRouteId());

        service.processEditSignals(user, parent, newRoute);

        verify(behaviorAnalysisService).analyzeAndSavePreferences(user);
        verify(behaviorAnalysisService).analyzeAndSaveDestinationPreferences(user, "rome");
    }

    @Test
    void null_destination_skips_destination_analysis() {
        AiRoute parent  = routeWith(routeJson("museum"), null, 1, null);
        AiRoute newRoute = routeWith(routeJson("cafe"), null, 2, parent.getRouteId());

        service.processEditSignals(user, parent, newRoute);

        verify(behaviorAnalysisService).analyzeAndSavePreferences(user);
        verify(behaviorAnalysisService, never()).analyzeAndSaveDestinationPreferences(any(), any());
    }

    @Test
    void mixed_edit_produces_both_add_and_remove_signals() {
        // Parent: 2 museums, 1 restaurant
        // New:    0 museums, 3 restaurants
        // Expected: 2x REMOVE museum, 2x ADD restaurant
        AiRoute parent  = routeWith(routeJson("museum", "museum", "restaurant"), "Berlin", 1, null);
        AiRoute newRoute = routeWith(routeJson("restaurant", "restaurant", "restaurant"),
                "Berlin", 2, parent.getRouteId());

        service.processEditSignals(user, parent, newRoute);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<UserInteraction>> captor = ArgumentCaptor.forClass(List.class);
        verify(interactionRepo).saveAll(captor.capture());

        List<UserInteraction> signals = captor.getValue();
        long museumRemoves   = signals.stream()
                .filter(i -> i.getInteractionType() == InteractionType.ROUTE_EDIT_REMOVE
                          && "museum".equals(i.getMetadata().get("category")))
                .count();
        long restaurantAdds = signals.stream()
                .filter(i -> i.getInteractionType() == InteractionType.ROUTE_EDIT_ADD
                          && "restaurant".equals(i.getMetadata().get("category")))
                .count();

        assertThat(museumRemoves).isEqualTo(2);
        assertThat(restaurantAdds).isEqualTo(2);
    }
}
