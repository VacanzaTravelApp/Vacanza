"""Database session and engine."""

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import get_settings
from app.db.base import Base

# Import models to register them with Base
from app.db.models import Conversation, Message, MessageEmbedding  # noqa: F401

engine = create_engine(
    get_settings().database_url_resolved,
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Session:
    """Dependency that yields a database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
