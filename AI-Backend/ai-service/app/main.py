"""FastAPI application entry point."""

from fastapi import FastAPI

from app.api.routes import health

app = FastAPI(
    title="Vacanza AI Service",
    description="Python microservice for AI-powered features",
    version="0.1.0",
)

app.include_router(health.router, prefix="/health", tags=["health"])
