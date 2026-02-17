package com.vacanza.backend.controller;

import com.vacanza.backend.entity.User;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.integration.ai.AiServiceClient;
import com.vacanza.backend.security.CurrentUserProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/chat")
@RequiredArgsConstructor
public class ChatProxyController {

    private final AiServiceClient aiServiceClient;
    private final CurrentUserProvider currentUserProvider;

    @PostMapping("/conversations")
    public ResponseEntity<AiChatDto.ConversationCreateResponse> createConversation() {
        User user = currentUserProvider.getCurrentUserEntity();
        return ResponseEntity.ok(
                aiServiceClient.createConversation(user.getUserId()).block()
        );
    }

    @GetMapping("/conversations")
    public ResponseEntity<List<AiChatDto.ConversationListItem>> listConversations(
            @RequestParam(required = false) Integer limit,
            @RequestParam(required = false) Integer offset) {
        User user = currentUserProvider.getCurrentUserEntity();
        List<AiChatDto.ConversationListItem> list = aiServiceClient
                .listConversations(user.getUserId(), limit, offset)
                .block();
        return ResponseEntity.ok(list);
    }

    @PostMapping("/conversations/{conversationId}/messages")
    public ResponseEntity<AiChatDto.MessageSendResponse> sendMessage(
            @PathVariable UUID conversationId,
            @RequestBody AiChatDto.MessageSendRequest body) {
        User user = currentUserProvider.getCurrentUserEntity();
        return ResponseEntity.ok(
                aiServiceClient.sendMessage(user.getUserId(), conversationId, body).block()
        );
    }

    @GetMapping("/conversations/{conversationId}/messages")
    public ResponseEntity<List<AiChatDto.MessageItem>> getMessages(
            @PathVariable UUID conversationId,
            @RequestParam(required = false) Integer limit,
            @RequestParam(required = false) Integer offset) {
        User user = currentUserProvider.getCurrentUserEntity();
        List<AiChatDto.MessageItem> list = aiServiceClient
                .getMessages(user.getUserId(), conversationId, limit, offset)
                .block();
        return ResponseEntity.ok(list);
    }
}
