"""Dependency injection utilities."""

from fastapi import Depends
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.db.session import get_db
from app.repositories import (
    ConversationRepository,
    MessageEmbeddingRepository,
    MessageRepository,
)


def get_conversation_repo(db: Session = Depends(get_db)) -> ConversationRepository:
    """ConversationRepository dependency."""
    return ConversationRepository(db)


def get_message_repo(db: Session = Depends(get_db)) -> MessageRepository:
    """MessageRepository dependency."""
    return MessageRepository(db)


def get_message_embedding_repo(
    db: Session = Depends(get_db),
) -> MessageEmbeddingRepository:
    """MessageEmbeddingRepository dependency."""
    return MessageEmbeddingRepository(db)


__all__ = [
    "Settings",
    "get_settings",
    "get_db",
    "get_conversation_repo",
    "get_message_repo",
    "get_message_embedding_repo",
]
