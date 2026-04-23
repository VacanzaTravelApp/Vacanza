package com.vacanza.backend.integration.viator;

/**
 * Thrown when the Viator Partner API cannot be reached (network, DNS, timeout, etc.).
 * HTTP-level errors are handled inside {@link ViatorClient} without throwing.
 */
public class ViatorPartnerUnavailableException extends RuntimeException {

    public ViatorPartnerUnavailableException(String message, Throwable cause) {
        super(message, cause);
    }
}
