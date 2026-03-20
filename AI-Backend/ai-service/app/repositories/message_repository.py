"""Message CRUD operations."""

import uuid
from typing import Sequence

from sqlalchemy.orm import Session

from app.db.models import Message


class MessageRepository:
    """Repository for Message entity."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def create(
        self,
        conversation_id: uuid.UUID,
        role: str,
        content: str,
    ) -> Message:
        """Create a new message."""
        message = Message(
            conversation_id=conversation_id,
            role=role,
            content=content,
        )
        self.db.add(message)
        self.db.commit()
        self.db.refresh(message)
        return message

    def get_by_id(self, message_id: uuid.UUID) -> Message | None:
        """Get message by ID."""
        return self.db.get(Message, message_id)

    def list_by_conversation(
        self,
        conversation_id: uuid.UUID,
        limit: int = 100,
        offset: int = 0,
    ) -> Sequence[Message]:
        """List messages in a conversation."""
        return (
            self.db.query(Message)
            .filter(Message.conversation_id == conversation_id)
            .order_by(Message.created_at.asc())
            .limit(limit)
            .offset(offset)
            .all()
        )

    def update(self, message_id: uuid.UUID, content: str) -> Message | None:
        """Update message content."""
        message = self.get_by_id(message_id)
        if message is None:
            return None
        message.content = content
        self.db.commit()
        self.db.refresh(message)
        return message

    def delete(self, message_id: uuid.UUID) -> bool:
        """Delete a message (cascades to embeddings)."""
        message = self.get_by_id(message_id)
        if message is None:
            return False
        self.db.delete(message)
        self.db.commit()
        return True
