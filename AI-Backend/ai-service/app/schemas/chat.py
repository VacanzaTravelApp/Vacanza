"""Chat API schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class UserProfileForAi(BaseModel):
    """User profile for AI personalization (from X-User-Profile header)."""

    displayName: str | None = None
    firstName: str | None = None
    middleName: str | None = None
    lastName: str | None = None
    preferredName: str | None = None
    country: str | None = None
    birthDate: str | None = None
    gender: str | None = None
    budget: str | None = None
    profileImageUrl: str | None = None
    joinDate: str | None = None


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
