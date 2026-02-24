package com.vacanza.backend.exceptions;

import org.springframework.http.HttpStatus;

public class BookingException extends RuntimeException {

    private final HttpStatus status;

    public BookingException(String message, HttpStatus status) {
        super(message);
        this.status = status;
    }

    public BookingException(String message, HttpStatus status, Throwable cause) {
        super(message, cause);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public static BookingException validationError(String message) {
        return new BookingException(message, HttpStatus.BAD_REQUEST);
    }

    public static BookingException providerError(String message) {
        return new BookingException(message, HttpStatus.BAD_GATEWAY);
    }

    public static BookingException timeout(String message) {
        return new BookingException(message, HttpStatus.GATEWAY_TIMEOUT);
    }
}
