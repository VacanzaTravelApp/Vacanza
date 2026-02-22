"""Chat API endpoints."""

import json
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException

from app.api.deps import (
    get_conversation_repo,
    get_message_embedding_repo,
    get_message_repo,
    get_settings,
)
from app.core.config import Settings
from app.repositories import (
    ConversationRepository,
    MessageEmbeddingRepository,
    MessageRepository,
)
from app.schemas.chat import (
    ConversationCreateResponse,
    ConversationListItem,
    MessageItem,
    MessageSend,
    MessageSendResponse,
    UserProfileForAi,
)
from app.services.chat_service import get_ai_response

router = APIRouter()

X_USER_ID = "X-User-Id"
X_USER_PROFILE = "X-User-Profile"


def _parse_x_user_id(x_user_id: str | None = Header(None, alias=X_USER_ID)) -> uuid.UUID | None:
    """Parse X-User-Id header. Returns None if missing, raises 400 if invalid UUID."""
    if not x_user_id or not x_user_id.strip():
        return None
    try:
        return uuid.UUID(x_user_id.strip())
    except ValueError:
        raise HTTPException(status_code=400, detail="X-User-Id must be a valid UUID")


def _require_x_user_id(x_user_id: str | None = Header(None, alias=X_USER_ID)) -> uuid.UUID:
    """Require X-User-Id header. 400 if missing or invalid UUID."""
    if not x_user_id or not x_user_id.strip():
        raise HTTPException(status_code=400, detail="X-User-Id header required")
    try:
        return uuid.UUID(x_user_id.strip())
    except ValueError:
        raise HTTPException(status_code=400, detail="X-User-Id must be a valid UUID")


def _parse_x_user_profile(
    x_user_profile: str | None = Header(None, alias=X_USER_PROFILE),
) -> UserProfileForAi | None:
    """Parse X-User-Profile header (JSON). Returns None if missing or invalid."""
    if not x_user_profile or not x_user_profile.strip():
        return None
    try:
        data = json.loads(x_user_profile.strip())
        return UserProfileForAi.model_validate(data)
    except (json.JSONDecodeError, ValueError):
        return None


@router.post("/conversations", response_model=ConversationCreateResponse)
def create_conversation(
    user_id: uuid.UUID = Depends(_require_x_user_id),
    repo: ConversationRepository = Depends(get_conversation_repo),
) -> ConversationCreateResponse:
    """Create a new conversation. user_id required from X-User-Id header."""
    conversation = repo.create(user_id=user_id)
    return ConversationCreateResponse(id=conversation.id)


@router.get("/conversations", response_model=list[ConversationListItem])
def list_conversations(
    user_id: uuid.UUID | None = Depends(_parse_x_user_id),
    limit: int = 100,
    offset: int = 0,
    repo: ConversationRepository = Depends(get_conversation_repo),
) -> list[ConversationListItem]:
    """List user's conversations. user_id from X-User-Id header only (no query param)."""
    conversations = repo.list(user_id=user_id, limit=limit, offset=offset)
    return [ConversationListItem.model_validate(c) for c in conversations]


@router.post("/conversations/{conversation_id}/messages", response_model=MessageSendResponse)
async def send_message(
    conversation_id: uuid.UUID,
    body: MessageSend,
    user_profile: UserProfileForAi | None = Depends(_parse_x_user_profile),
    settings: Settings = Depends(get_settings),
    conversation_repo: ConversationRepository = Depends(get_conversation_repo),
    message_repo: MessageRepository = Depends(get_message_repo),
    message_embedding_repo: MessageEmbeddingRepository = Depends(get_message_embedding_repo),
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
        message_embedding_repo=message_embedding_repo,
        conversation_repo=conversation_repo,
        conversation_id=conversation_id,
        user_content=body.content,
        user_profile=user_profile,
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
