"""Conversation and message schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class ConversationCreate(BaseModel):
    """Schema for creating a conversation."""

    user_id: UUID | None = None


class ConversationResponse(BaseModel):
    """Schema for conversation response."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime
    user_id: UUID | None


class MessageCreate(BaseModel):
    """Schema for creating a message."""

    role: str
    content: str


class MessageResponse(BaseModel):
    """Schema for message response."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    conversation_id: UUID
    role: str
    content: str
    created_at: datetime
