package com.vacanza.backend.exceptions;

import org.springframework.http.HttpStatus;

/**
 * Authentication/authorization ile ilgili backend-controlled hata durumları.
 * Firebase'in handle ettiği (password, credential) hatalar burada YOK.
 */
public class AuthException extends RuntimeException {

    private final HttpStatus status;

    public AuthException(String message, HttpStatus status) {
        super(message);
        this.status = status;
    }

    public AuthException(String message, HttpStatus status, Throwable cause) {
        super(message, cause);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }

    // --- Factory Methods ---

    public static AuthException emailAlreadyExists() {
        return new AuthException("Email already exists", HttpStatus.CONFLICT);
    }

    public static AuthException userNotFound() {
        return new AuthException("User not found", HttpStatus.NOT_FOUND);
    }

    public static AuthException accountNotVerified() {
        return new AuthException("Account not verified. Please verify your email first.", HttpStatus.FORBIDDEN);
    }

    public static AuthException unauthorized(String message) {
        return new AuthException(message, HttpStatus.UNAUTHORIZED);
    }

    public static AuthException validationError(String message) {
        return new AuthException(message, HttpStatus.BAD_REQUEST);
    }
}
