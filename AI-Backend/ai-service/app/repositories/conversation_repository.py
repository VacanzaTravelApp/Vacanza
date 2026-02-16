"""Conversation CRUD operations."""

import uuid
from typing import Sequence

from sqlalchemy.orm import Session

from app.db.models import Conversation


class ConversationRepository:
    """Repository for Conversation entity."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, user_id: uuid.UUID | None = None) -> Conversation:
        """Create a new conversation."""
        conversation = Conversation(user_id=user_id)
        self.db.add(conversation)
        self.db.commit()
        self.db.refresh(conversation)
        return conversation

    def get_by_id(self, conversation_id: uuid.UUID) -> Conversation | None:
        """Get conversation by ID."""
        return self.db.get(Conversation, conversation_id)

    def list(
        self,
        user_id: uuid.UUID | None = None,
        limit: int = 100,
        offset: int = 0,
    ) -> Sequence[Conversation]:
        """List conversations, optionally filtered by user_id."""
        query = self.db.query(Conversation)
        if user_id is not None:
            query = query.filter(Conversation.user_id == user_id)
        return query.order_by(Conversation.created_at.desc()).limit(limit).offset(offset).all()

    def update_updated_at(self, conversation_id: uuid.UUID) -> Conversation | None:
        """Update the updated_at timestamp."""
        from datetime import datetime, timezone

        from sqlalchemy import update

        stmt = update(Conversation).where(Conversation.id == conversation_id).values(
            updated_at=datetime.now(timezone.utc)
        )
        self.db.execute(stmt)
        self.db.commit()
        return self.get_by_id(conversation_id)

    def delete(self, conversation_id: uuid.UUID) -> bool:
        """Delete a conversation (cascades to messages and embeddings)."""
        conversation = self.get_by_id(conversation_id)
        if conversation is None:
            return False
        self.db.delete(conversation)
        self.db.commit()
        return True
