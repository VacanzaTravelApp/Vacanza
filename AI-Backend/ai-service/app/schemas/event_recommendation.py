"""Schemas for POST /events/recommend-for-route."""

from pydantic import BaseModel, Field


class DaySummary(BaseModel):
    day: int
    title: str
    categories: list[str] = Field(default_factory=list)


class RouteSummary(BaseModel):
    destination: str
    total_days: int
    start_date: str | None = None
    day_summaries: list[DaySummary] = Field(default_factory=list)


class UserPreferenceSummary(BaseModel):
    travel_style: str | None = None
    favorite_categories: list[str] = Field(default_factory=list)
    event_interest: str | None = None
    preferred_language: str | None = "tr"


class AvailableEvent(BaseModel):
    id: str
    name: str
    description: str | None = None
    start_time: str | None = None
    end_time: str | None = None
    venue_name: str | None = None
    category: str | None = None
    latitude: float | None = None
    longitude: float | None = None


class EventRecommendRequest(BaseModel):
    route_summary: RouteSummary
    user_preferences: UserPreferenceSummary
    available_events: list[AvailableEvent]


class RecommendedEventResult(BaseModel):
    event_id: str
    matched_day: int | None = None
    match_reason: str
    relevance_score: float = 0.0


class EventRecommendResponse(BaseModel):
    message: str
    recommended_events: list[RecommendedEventResult] = Field(default_factory=list)
