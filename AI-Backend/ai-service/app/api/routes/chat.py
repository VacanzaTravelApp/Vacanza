"""Chat API endpoints."""

import uuid

from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import get_conversation_repo, get_message_repo, get_settings
from app.core.config import Settings
from app.repositories import ConversationRepository, MessageRepository
from app.schemas.chat import (
    ConversationCreateResponse,
    ConversationListItem,
    MessageItem,
    MessageSend,
    MessageSendResponse,
)
from app.services.chat_service import get_ai_response

router = APIRouter()


@router.post("/conversations", response_model=ConversationCreateResponse)
def create_conversation(
    user_id: uuid.UUID | None = None,
    repo: ConversationRepository = Depends(get_conversation_repo),
) -> ConversationCreateResponse:
    """Create a new conversation."""
    conversation = repo.create(user_id=user_id)
    return ConversationCreateResponse(id=conversation.id)


@router.get("/conversations", response_model=list[ConversationListItem])
def list_conversations(
    user_id: uuid.UUID | None = None,
    limit: int = 100,
    offset: int = 0,
    repo: ConversationRepository = Depends(get_conversation_repo),
) -> list[ConversationListItem]:
    """List user's conversations."""
    conversations = repo.list(user_id=user_id, limit=limit, offset=offset)
    return [ConversationListItem.model_validate(c) for c in conversations]


@router.post("/conversations/{conversation_id}/messages", response_model=MessageSendResponse)
async def send_message(
    conversation_id: uuid.UUID,
    body: MessageSend,
    settings: Settings = Depends(get_settings),
    conversation_repo: ConversationRepository = Depends(get_conversation_repo),
    message_repo: MessageRepository = Depends(get_message_repo),
) -> MessageSendResponse:
    """Send a message and get AI response. Context is preserved within conversation."""
    if conversation_repo.get_by_id(conversation_id) is None:
        raise HTTPException(status_code=404, detail="Conversation not found")

    if not settings.openai_api_key:
        raise HTTPException(
            status_code=503,
            detail="OpenAI API key not configured",
        )

    content = await get_ai_response(
        settings=settings,
        message_repo=message_repo,
        conversation_id=conversation_id,
        user_content=body.content,
    )

    conversation_repo.update_updated_at(conversation_id)

    return MessageSendResponse(content=content)


@router.get("/conversations/{conversation_id}/messages", response_model=list[MessageItem])
def get_conversation_history(
    conversation_id: uuid.UUID,
    limit: int = 100,
    offset: int = 0,
    conversation_repo: ConversationRepository = Depends(get_conversation_repo),
    message_repo: MessageRepository = Depends(get_message_repo),
) -> list[MessageItem]:
    """Get conversation message history."""
    if conversation_repo.get_by_id(conversation_id) is None:
        raise HTTPException(status_code=404, detail="Conversation not found")

    messages = message_repo.list_by_conversation(
        conversation_id=conversation_id,
        limit=limit,
        offset=offset,
    )
    return [MessageItem.model_validate(m) for m in messages]
