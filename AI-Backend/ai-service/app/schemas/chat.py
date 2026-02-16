"""Chat API schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class ConversationCreateResponse(BaseModel):
    """Response when creating a new conversation."""

    id: UUID


class ConversationListItem(BaseModel):
    """Conversation in list response."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime
    user_id: UUID | None


class MessageSend(BaseModel):
    """Request body for sending a message."""

    content: str


class MessageItem(BaseModel):
    """Single message in history/response."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    role: str
    content: str
    created_at: datetime


class MessageSendResponse(BaseModel):
    """AI response when sending a message."""

    content: str
