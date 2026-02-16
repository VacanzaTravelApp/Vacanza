package com.vacanza.backend.integration.ai;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/**
 * DTOs for AI chat service proxy requests/responses.
 * AI service returns snake_case JSON.
 */
public final class AiChatDto {

    private AiChatDto() {}

    /** Request body for sending a message. */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MessageSendRequest {
        private String content;
    }

    /** Response when creating a conversation. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ConversationCreateResponse {
        private UUID id;
    }

    /** Conversation item in list response. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ConversationListItem {
        private UUID id;
        @JsonProperty("created_at")
        private Instant createdAt;
        @JsonProperty("updated_at")
        private Instant updatedAt;
        @JsonProperty("user_id")
        private UUID userId;
    }

    /** Single message in history. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MessageItem {
        private UUID id;
        private String role;
        private String content;
        @JsonProperty("created_at")
        private Instant createdAt;
    }

    /** AI response when sending a message. */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MessageSendResponse {
        private String content;
    }
}
