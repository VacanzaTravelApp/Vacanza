package com.vacanza.backend.exceptions;

import com.vacanza.backend.component.SystemLogCollector;
import com.vacanza.backend.dto.response.ErrorResponse;
import com.vacanza.backend.integration.viator.ViatorPartnerUnavailableException;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

import java.util.stream.Collectors;

/**
 * Tüm controller'lar için merkezi hata yönetimi.
 * Tutarlı JSON error response döndürür.
 */
@Slf4j
@RestControllerAdvice
@RequiredArgsConstructor
public class GlobalExceptionHandler {

    private final SystemLogCollector systemLogCollector;

    /**
     * AuthException: backend-controlled auth hataları
     * (email exists, user not found, account not verified)
     */
    @ExceptionHandler(AuthException.class)
    public ResponseEntity<ErrorResponse> handleAuthException(
            AuthException ex, HttpServletRequest request) {

        ErrorResponse body = ErrorResponse.of(
                ex.getStatus().value(),
                ex.getStatus().getReasonPhrase(),
                ex.getMessage(),
                request.getRequestURI());

        systemLogCollector.recordError(request.getRequestURI(), "AuthException: " + ex.getMessage());
        return new ResponseEntity<>(body, ex.getStatus());
    }

    /**
     * ResponseStatusException: mevcut kodda kullanılan Spring exception'ları
     */
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ErrorResponse> handleResponseStatus(
            ResponseStatusException ex, HttpServletRequest request) {

        HttpStatus status = HttpStatus.valueOf(ex.getStatusCode().value());

        ErrorResponse body = ErrorResponse.of(
                status.value(),
                status.getReasonPhrase(),
                ex.getReason(),
                request.getRequestURI());

        if (status.is5xxServerError()) {
            systemLogCollector.recordError(request.getRequestURI(), "ResponseStatusException: " + ex.getReason());
        }
        return new ResponseEntity<>(body, status);
    }

    /**
     * MethodArgumentNotValidException: @Valid annotation validation hataları
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(
            MethodArgumentNotValidException ex, HttpServletRequest request) {

        String message = ex.getBindingResult().getFieldErrors().stream()
                .map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
                .collect(Collectors.joining(", "));

        ErrorResponse body = ErrorResponse.of(
                HttpStatus.BAD_REQUEST.value(),
                HttpStatus.BAD_REQUEST.getReasonPhrase(),
                message,
                request.getRequestURI());

        // Validation errors usually shouldn't clutter the admin panel, so we skip logging them to systemLogCollector.
        return new ResponseEntity<>(body, HttpStatus.BAD_REQUEST);
    }

    /**
     * DataIntegrityViolationException: unique constraint ihlalleri (email already
     * exists vb.)
     */
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ErrorResponse> handleDataIntegrity(
            DataIntegrityViolationException ex, HttpServletRequest request) {

        String message = "Data integrity violation";

        // email unique constraint ihlali kontrolü
        if (ex.getMessage() != null && ex.getMessage().contains("uk_users_email")) {
            message = "Email already exists";
        }

        ErrorResponse body = ErrorResponse.of(
                HttpStatus.CONFLICT.value(),
                HttpStatus.CONFLICT.getReasonPhrase(),
                message,
                request.getRequestURI());

        systemLogCollector.recordError(request.getRequestURI(), "DataIntegrityViolation: " + message);
        return new ResponseEntity<>(body, HttpStatus.CONFLICT);
    }

    /**
     * BookingException: mevcut booking hataları
     */
    @ExceptionHandler(BookingException.class)
    public ResponseEntity<ErrorResponse> handleBookingException(
            BookingException ex, HttpServletRequest request) {

        ErrorResponse body = ErrorResponse.of(
                ex.getStatus().value(),
                ex.getStatus().getReasonPhrase(),
                ex.getMessage(),
                request.getRequestURI());

        systemLogCollector.recordError(request.getRequestURI(), "BookingException: " + ex.getMessage());
        return new ResponseEntity<>(body, ex.getStatus());
    }

    /**
     * EventException: event search / Ticketmaster API errors
     */
    @ExceptionHandler(EventException.class)
    public ResponseEntity<ErrorResponse> handleEventException(
            EventException ex, HttpServletRequest request) {

        ErrorResponse body = ErrorResponse.of(
                ex.getStatus().value(),
                ex.getStatus().getReasonPhrase(),
                ex.getMessage(),
                request.getRequestURI());

        systemLogCollector.recordError(request.getRequestURI(), "EventException: " + ex.getMessage());
        return new ResponseEntity<>(body, ex.getStatus());
    }

    /**
     * Viator Partner API transport failure (DNS, connection, timeout) when not handled inline.
     */
    @ExceptionHandler(ViatorPartnerUnavailableException.class)
    public ResponseEntity<ErrorResponse> handleViatorPartnerUnavailable(
            ViatorPartnerUnavailableException ex, HttpServletRequest request) {

        ErrorResponse body = ErrorResponse.of(
                HttpStatus.SERVICE_UNAVAILABLE.value(),
                HttpStatus.SERVICE_UNAVAILABLE.getReasonPhrase(),
                ex.getMessage() != null ? ex.getMessage() : "Viator Partner API unreachable",
                request.getRequestURI());

        systemLogCollector.recordError(request.getRequestURI(), "ViatorPartnerUnavailable: " + ex.getMessage());
        return new ResponseEntity<>(body, HttpStatus.SERVICE_UNAVAILABLE);
    }

    @ExceptionHandler(CurrencyException.class)
    public ResponseEntity<ErrorResponse> handleCurrencyException(
            CurrencyException ex, HttpServletRequest request) {

        ErrorResponse body = ErrorResponse.of(
                ex.getStatus().value(),
                ex.getStatus().getReasonPhrase(),
                ex.getMessage(),
                request.getRequestURI());

        systemLogCollector.recordError(request.getRequestURI(), "CurrencyException: " + ex.getMessage());
        return new ResponseEntity<>(body, ex.getStatus());
    }

    /**
     * Catch-all for unhandled 500 errors.
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleAllExceptions(
            Exception ex, HttpServletRequest request) {

        log.error("Unhandled exception at {}", request.getRequestURI(), ex);

        ErrorResponse body = ErrorResponse.of(
                HttpStatus.INTERNAL_SERVER_ERROR.value(),
                HttpStatus.INTERNAL_SERVER_ERROR.getReasonPhrase(),
                "An unexpected server error occurred.",
                request.getRequestURI());

        systemLogCollector.recordError(request.getRequestURI(), "Unhandled Exception: " + ex.getMessage());
        return new ResponseEntity<>(body, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
