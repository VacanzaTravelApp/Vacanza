package com.vacanza.backend.exceptions;

import lombok.Getter;
import org.springframework.http.HttpStatus;

/**
 * Custom exception for Currency Conversion and Forecasting errors.
 */
@Getter
public class CurrencyException extends RuntimeException {
    private final HttpStatus status;

    public CurrencyException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }
}
