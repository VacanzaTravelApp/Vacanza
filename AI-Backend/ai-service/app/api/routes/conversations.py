"""Conversation and message CRUD endpoints."""

import uuid

from fastapi import APIRouter, Body, Depends, HTTPException

from app.api.deps import get_conversation_repo, get_message_repo
from app.repositories import ConversationRepository, MessageRepository
from app.schemas.conversation import (
    ConversationCreate,
    ConversationResponse,
    MessageCreate,
    MessageResponse,
)

router = APIRouter()


@router.post("", response_model=ConversationResponse)
def create_conversation(
    body: ConversationCreate | None = Body(default=None),
    repo: ConversationRepository = Depends(get_conversation_repo),
) -> ConversationResponse:
    """Create a new conversation."""
    user_id = body.user_id if body else None
    conversation = repo.create(user_id=user_id)
    return ConversationResponse.model_validate(conversation)


@router.get("", response_model=list[ConversationResponse])
def list_conversations(
    user_id: uuid.UUID | None = None,
    limit: int = 100,
    offset: int = 0,
    repo: ConversationRepository = Depends(get_conversation_repo),
) -> list[ConversationResponse]:
    """List conversations."""
    conversations = repo.list(user_id=user_id, limit=limit, offset=offset)
    return [ConversationResponse.model_validate(c) for c in conversations]


@router.get("/{conversation_id}", response_model=ConversationResponse)
def get_conversation(
    conversation_id: uuid.UUID,
    repo: ConversationRepository = Depends(get_conversation_repo),
) -> ConversationResponse:
    """Get conversation by ID."""
    conversation = repo.get_by_id(conversation_id)
    if conversation is None:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return ConversationResponse.model_validate(conversation)


@router.delete("/{conversation_id}", status_code=204)
def delete_conversation(
    conversation_id: uuid.UUID,
    repo: ConversationRepository = Depends(get_conversation_repo),
) -> None:
    """Delete a conversation."""
    if not repo.delete(conversation_id):
        raise HTTPException(status_code=404, detail="Conversation not found")


# Messages
@router.post("/{conversation_id}/messages", response_model=MessageResponse)
def create_message(
    conversation_id: uuid.UUID,
    body: MessageCreate,
    conversation_repo: ConversationRepository = Depends(get_conversation_repo),
    message_repo: MessageRepository = Depends(get_message_repo),
) -> MessageResponse:
    """Create a message in a conversation."""
    if conversation_repo.get_by_id(conversation_id) is None:
        raise HTTPException(status_code=404, detail="Conversation not found")
    message = message_repo.create(
        conversation_id=conversation_id,
        role=body.role,
        content=body.content,
    )
    conversation_repo.update_updated_at(conversation_id)
    return MessageResponse.model_validate(message)


@router.get("/{conversation_id}/messages", response_model=list[MessageResponse])
def list_messages(
    conversation_id: uuid.UUID,
    limit: int = 100,
    offset: int = 0,
    conversation_repo: ConversationRepository = Depends(get_conversation_repo),
    message_repo: MessageRepository = Depends(get_message_repo),
) -> list[MessageResponse]:
    """List messages in a conversation."""
    if conversation_repo.get_by_id(conversation_id) is None:
        raise HTTPException(status_code=404, detail="Conversation not found")
    messages = message_repo.list_by_conversation(
        conversation_id=conversation_id,
        limit=limit,
        offset=offset,
    )
    return [MessageResponse.model_validate(m) for m in messages]
