"""FastAPI application entry point."""

from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.routes import ai, conversations, health
from app.core.config import get_settings
from app.db.migrate import run_migrations


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Run migrations on startup (like Spring Boot Flyway)."""
    import logging
    import os

    if os.getenv("RUN_MIGRATIONS", "true").lower() == "false":
        logging.getLogger("app").info("Migrations skipped (RUN_MIGRATIONS=false)")
    else:
        settings = get_settings()
        try:
            run_migrations(settings.database_url_resolved)
        except Exception as e:
            logging.getLogger("app").error("Migrations failed: %s", e)
            raise  # Fail fast in production
    yield


app = FastAPI(
    title="Vacanza AI Service",
    description="Python microservice for AI-powered features",
    version="0.1.0",
    lifespan=lifespan,
)

app.include_router(health.router, prefix="/health", tags=["health"])
app.include_router(ai.router, prefix="/ai", tags=["ai"])
app.include_router(conversations.router, prefix="/conversations", tags=["conversations"])
