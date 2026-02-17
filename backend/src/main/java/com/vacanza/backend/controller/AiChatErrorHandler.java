package com.vacanza.backend.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.reactive.function.client.WebClientRequestException;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.util.Map;

/**
 * Handles errors from AI chat proxy endpoints.
 * - WebClientResponseException (4xx/5xx from AI) → same status, AI's error body
 * - WebClientRequestException (connection/timeout) → 503 Service Unavailable
 */
@Slf4j
@RestControllerAdvice(assignableTypes = ChatProxyController.class)
public class AiChatErrorHandler {

    @ExceptionHandler(WebClientResponseException.class)
    public ResponseEntity<String> handleWebClientResponse(WebClientResponseException ex) {
        int status = ex.getStatusCode().value();
        String body = ex.getResponseBodyAsString();
        log.warn("AI service returned {}: {}", status, body);
        return ResponseEntity.status(status).body(body != null && !body.isBlank() ? body : ex.getMessage());
    }

    @ExceptionHandler(WebClientRequestException.class)
    public ResponseEntity<Map<String, String>> handleWebClientRequest(WebClientRequestException ex) {
        log.error("AI service unavailable (connection/timeout)", ex);
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(Map.of("error", "AI service unavailable", "detail", "Connection or timeout"));
    }
}
