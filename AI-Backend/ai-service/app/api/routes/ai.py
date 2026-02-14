"""AI-related endpoints."""

from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import get_settings
from app.core.config import Settings
from app.services.openai_service import test_connection

router = APIRouter()


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
