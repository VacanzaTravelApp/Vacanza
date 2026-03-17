package com.vacanza.backend.exceptions;

import org.springframework.http.HttpStatus;

/**
 * Exception for event-related errors (Ticketmaster API failures, validation, etc.).
 * Follows the same pattern as BookingException.
 */
public class EventException extends RuntimeException {

    private final HttpStatus status;

    public EventException(String message, HttpStatus status) {
        super(message);
        this.status = status;
    }

    public EventException(String message, HttpStatus status, Throwable cause) {
        super(message, cause);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public static EventException validationError(String message) {
        return new EventException(message, HttpStatus.BAD_REQUEST);
    }

    public static EventException providerError(String message) {
        return new EventException(message, HttpStatus.BAD_GATEWAY);
    }

    public static EventException timeout(String message) {
        return new EventException(message, HttpStatus.GATEWAY_TIMEOUT);
    }
}
