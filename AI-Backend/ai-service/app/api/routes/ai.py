"""AI-related endpoints."""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.api.deps import get_settings
from app.core.config import Settings
from app.services.embedding_service import EmbeddingServiceError, create_embedding_service
from app.services.openai_service import test_connection

router = APIRouter()


class EmbedRequest(BaseModel):
    """Request body for embedding endpoint."""

    text: str


@router.get("/test")
async def test_openai_connection(
    settings: Settings = Depends(get_settings),
) -> dict[str, str]:
    """Verifies OpenAI API connection.

    Returns:
        Success status and message from OpenAI.
    """
    success, message = await test_connection(settings)
    if not success:
        raise HTTPException(
            status_code=503,
            detail=f"OpenAI connection failed: {message}",
        )
    return {"status": "ok", "message": message}


@router.post("/embed")
async def embed_text(
    body: EmbedRequest,
    settings: Settings = Depends(get_settings),
) -> dict[str, list[float] | int]:
    """Generate embedding for text (for testing embedding service).

    POST body: {"text": "your text here"}

    Returns:
        Embedding vector (1536 dims) and dimension.
    """
    text = body.text
    service = create_embedding_service(settings)
    if not service:
        raise HTTPException(
            status_code=503,
            detail="OpenAI API key not configured",
        )
    try:
        embedding = service.embed(text)
        return {"embedding": embedding, "dimension": len(embedding)}
    except EmbeddingServiceError as e:
        raise HTTPException(status_code=400, detail=str(e))
