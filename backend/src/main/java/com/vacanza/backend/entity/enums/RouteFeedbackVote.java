package com.vacanza.backend.entity.enums;

public enum RouteFeedbackVote {
    UP,
    DOWN;

    public String toApiString() {
        return name();
    }
}
