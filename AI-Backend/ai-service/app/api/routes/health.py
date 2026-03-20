"""Health check endpoints."""

from fastapi import APIRouter

router = APIRouter()


@router.get("", status_code=200)
def health_check() -> dict[str, str]:
    """Returns service health status.

    Returns:
        Status message indicating the service is running.
    """
    return {"status": "ok"}
