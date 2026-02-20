"""MessageEmbedding CRUD operations."""

import uuid
from typing import Sequence

from sqlalchemy.orm import Session

from app.db.models import MessageEmbedding


class MessageEmbeddingRepository:
    """Repository for MessageEmbedding entity."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def create(
        self,
        message_id: uuid.UUID,
        embedding: list[float],
        model: str,
        user_id: uuid.UUID | None = None,
    ) -> MessageEmbedding:
        """Create a new message embedding."""
        msg_embedding = MessageEmbedding(
            message_id=message_id,
            embedding=embedding,
            model=model,
            user_id=user_id,
        )
        self.db.add(msg_embedding)
        self.db.commit()
        self.db.refresh(msg_embedding)
        return msg_embedding

    def get_by_id(self, embedding_id: uuid.UUID) -> MessageEmbedding | None:
        """Get message embedding by ID."""
        return self.db.get(MessageEmbedding, embedding_id)

    def list_by_message(
        self,
        message_id: uuid.UUID,
        limit: int = 10,
    ) -> Sequence[MessageEmbedding]:
        """List embeddings for a message."""
        return (
            self.db.query(MessageEmbedding)
            .filter(MessageEmbedding.message_id == message_id)
            .order_by(MessageEmbedding.created_at.desc())
            .limit(limit)
            .all()
        )

    def delete(self, embedding_id: uuid.UUID) -> bool:
        """Delete a message embedding."""
        msg_embedding = self.get_by_id(embedding_id)
        if msg_embedding is None:
            return False
        self.db.delete(msg_embedding)
        self.db.commit()
        return True
