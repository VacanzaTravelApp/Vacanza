package com.vacanza.backend.dto.enums;

import java.util.Locale;

public enum PoiFeedbackEventType {
    THUMBS_UP,
    THUMBS_DOWN,
    REMOVE_POI;

    public static PoiFeedbackEventType fromApi(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            return valueOf(raw.trim().toUpperCase(Locale.ROOT).replace('-', '_'));
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
