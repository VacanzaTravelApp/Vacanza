package com.vacanza.backend.dto.request;

import java.util.UUID;

public record RouteFeedbackRequestDTO(UUID routeId, String eventType) {}
