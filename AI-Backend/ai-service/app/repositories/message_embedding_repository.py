"""MessageEmbedding CRUD operations."""

import uuid
from typing import Sequence

from sqlalchemy.orm import Session, joinedload

from app.db.models import Message, MessageEmbedding


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

    def search_similar(
        self,
        query_embedding: list[float],
        user_id: uuid.UUID | None,
        exclude_conversation_id: uuid.UUID | None = None,
        limit: int = 10,
        max_distance: float | None = None,
    ) -> Sequence[MessageEmbedding]:
        """Find most similar message embeddings by cosine distance.

        Args:
            query_embedding: Query vector (1536 dims).
            user_id: Filter by user (None = returns empty).
            exclude_conversation_id: Exclude messages from this conversation (for "old" context).
            limit: Max results (default 10).
            max_distance: Optional cosine distance threshold; results with distance > this are excluded.

        Returns:
            MessageEmbedding objects ordered by similarity (closest first), with message loaded.
        """
        if user_id is None:
            return []

        distance_col = MessageEmbedding.embedding.cosine_distance(query_embedding)
        fetch_limit = limit * 2 if max_distance is not None else limit

        query = (
            self.db.query(MessageEmbedding, distance_col)
            .options(joinedload(MessageEmbedding.message))
            .filter(MessageEmbedding.user_id == user_id)
        )

        if exclude_conversation_id is not None:
            query = query.join(Message).filter(
                Message.conversation_id != exclude_conversation_id
            )

        rows = query.order_by(distance_col).limit(fetch_limit).all()

        if max_distance is None:
            return [me for me, _ in rows]

        return [
            me
            for me, d in rows
            if d is not None and float(d) <= max_distance
        ][:limit]
