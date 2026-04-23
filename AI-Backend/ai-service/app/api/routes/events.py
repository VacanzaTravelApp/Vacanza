"""Event recommendation API."""

from fastapi import APIRouter, Depends

from app.api.deps import get_settings
from app.core.config import Settings
from app.schemas.event_recommendation import EventRecommendRequest, EventRecommendResponse
from app.services.event_recommendation_service import recommend_events_for_route

router = APIRouter(prefix="/events", tags=["events"])


@router.post("/recommend-for-route", response_model=EventRecommendResponse)
async def recommend_for_route(
    request: EventRecommendRequest,
    settings: Settings = Depends(get_settings),
) -> EventRecommendResponse:
    return await recommend_events_for_route(request, settings)
