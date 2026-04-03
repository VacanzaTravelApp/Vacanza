package com.vacanza.backend.integration.ai;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Client for AI chat service. Proxies requests with X-User-Id and X-User-Profile headers.
 */
@Slf4j
@Component
public class AiServiceClient {

    private static final String X_USER_ID = "X-User-Id";
    private static final String X_USER_PROFILE = "X-User-Profile";
    private static final String X_USER_AI_PREFS = "X-User-Ai-Preferences";

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    public AiServiceClient(
            @Qualifier("aiWebClient") WebClient webClient,
            ObjectMapper objectMapper) {
        this.webClient = webClient;
        this.objectMapper = objectMapper;
    }

    /**
     * POST /chat/conversations — Create a new conversation.
     */
    public Mono<AiChatDto.ConversationCreateResponse> createConversation(UUID userId) {
        return webClient.post()
                .uri("/chat/conversations")
                .header(X_USER_ID, userId.toString())
                .contentType(MediaType.APPLICATION_JSON)
                .retrieve()
                .bodyToMono(AiChatDto.ConversationCreateResponse.class);
    }

    /**
     * GET /chat/conversations — List user's conversations.
     */
    public Mono<List<AiChatDto.ConversationListItem>> listConversations(
            UUID userId,
            Integer limit,
            Integer offset) {
        return webClient.get()
                .uri(uriBuilder -> {
                    uriBuilder.path("/chat/conversations");
                    if (limit != null) uriBuilder.queryParam("limit", limit);
                    if (offset != null) uriBuilder.queryParam("offset", offset);
                    return uriBuilder.build();
                })
                .header(X_USER_ID, userId.toString())
                .retrieve()
                .bodyToMono(new ParameterizedTypeReference<>() {});
    }

    /**
     * POST /chat/conversations/{id}/messages — Send message, get AI response.
     *
     * @param profile Optional user profile for AI personalization (sent as X-User-Profile header).
     */
    public Mono<AiChatDto.MessageSendResponse> sendMessage(
            UUID userId,
            UUID conversationId,
            AiChatDto.MessageSendRequest body,
            UserProfileForAi profile,
            List<AiChatDto.ExtractedPreference> existingAiPrefs) {
        var spec = webClient.post()
                .uri("/chat/conversations/{id}/messages", conversationId)
                .header(X_USER_ID, userId.toString())
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(body);

        if (profile != null) {
            try {
                spec = spec.header(X_USER_PROFILE, objectMapper.writeValueAsString(profile));
            } catch (JsonProcessingException e) {
                // Skip profile on serialization error
            }
        }

        if (existingAiPrefs != null && !existingAiPrefs.isEmpty()) {
            try {
                spec = spec.header(X_USER_AI_PREFS, objectMapper.writeValueAsString(existingAiPrefs));
            } catch (JsonProcessingException e) {
                // Skip on serialization error
            }
        }

        return spec.retrieve()
                .bodyToMono(AiChatDto.MessageSendResponse.class);
    }

    /**
     * GET /chat/conversations/{id}/messages — Get conversation history.
     */
    public Mono<List<AiChatDto.MessageItem>> getMessages(
            UUID userId,
            UUID conversationId,
            Integer limit,
            Integer offset) {
        return webClient.get()
                .uri(uriBuilder -> {
                    var builder = uriBuilder.path("/chat/conversations/{id}/messages");
                    if (limit != null) builder.queryParam("limit", limit);
                    if (offset != null) builder.queryParam("offset", offset);
                    return builder.build(conversationId);
                })
                .header(X_USER_ID, userId.toString())
                .retrieve()
                .bodyToMono(new ParameterizedTypeReference<>() {});
    }

    /**
     * POST /events/recommend-for-route — LLM ranking and personalized message for Ticketmaster events.
     *
     * @return empty if the call fails or returns no body
     */
    public Optional<AiChatDto.EventRecommendAiResponse> recommendEventsForRoute(
            UUID userId,
            AiChatDto.EventRecommendAiRequest body) {
        if (body == null || body.getAvailableEvents() == null || body.getAvailableEvents().isEmpty()) {
            return Optional.empty();
        }
        try {
            AiChatDto.EventRecommendAiResponse response = webClient.post()
                    .uri("/events/recommend-for-route")
                    .header(X_USER_ID, userId.toString())
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(AiChatDto.EventRecommendAiResponse.class)
                    .block(Duration.ofSeconds(60));
            return Optional.ofNullable(response);
        } catch (Exception e) {
            log.warn("AI event recommendation failed: {}", e.getMessage());
            return Optional.empty();
        }
    }
}
