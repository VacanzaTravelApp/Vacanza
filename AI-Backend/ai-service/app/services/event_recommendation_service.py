"""LLM-based ranking and message for route-scoped events."""

import json
import logging
import re

from langchain_core.messages import HumanMessage, SystemMessage
from pydantic import ValidationError

from app.core.config import get_settings
from app.schemas.event_recommendation import (
    AvailableEvent,
    EventRecommendRequest,
    EventRecommendResponse,
    RecommendedEventResult,
    RouteSummary,
    UserPreferenceSummary,
)
from app.services.openai_service import create_chat_model

logger = logging.getLogger(__name__)

EMPTY_MESSAGE = "Bu tarihler için uygun etkinlik bulunamadı."
FALLBACK_MESSAGE_TR = "Rotanız için bulunan etkinlikler:"
GENERIC_REASON = "Rota ve tercihlerinize göre önerildi."


def _extract_json_object(text: str) -> dict | None:
    text = text.strip()
    fence = re.search(r"```(?:json)?\s*([\s\S]*?)\s*```", text)
    if fence:
        text = fence.group(1).strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    start = text.find("{")
    if start < 0:
        return None
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                try:
                    return json.loads(text[start : i + 1])
                except json.JSONDecodeError:
                    return None
    return None


def _format_days(route: RouteSummary) -> str:
    lines: list[str] = []
    for d in route.day_summaries:
        cats = ", ".join(d.categories) if d.categories else "(none)"
        lines.append(f"- Day {d.day}: {d.title} (categories: {cats})")
    return "\n".join(lines) if lines else "(no day breakdown)"


def _format_events(events: list[AvailableEvent]) -> str:
    lines: list[str] = []
    for i, e in enumerate(events, start=1):
        lines.append(
            f"{i}. {e.name} | {e.category or '-'} | {e.start_time or '-'} | {e.venue_name or '-'}"
        )
    return "\n".join(lines)


def _fallback_all_events(
    request: EventRecommendRequest,
    message: str | None = None,
) -> EventRecommendResponse:
    msg = message or FALLBACK_MESSAGE_TR
    return EventRecommendResponse(
        message=msg,
        recommended_events=[
            RecommendedEventResult(
                event_id=e.id,
                matched_day=None,
                match_reason=GENERIC_REASON,
                relevance_score=0.5,
            )
            for e in request.available_events
        ],
    )


async def recommend_events_for_route(request: EventRecommendRequest) -> EventRecommendResponse:
    if not request.available_events:
        return EventRecommendResponse(message=EMPTY_MESSAGE, recommended_events=[])

    settings = get_settings()
    route = request.route_summary
    prefs = request.user_preferences
    lang = (prefs.preferred_language or "tr").strip() or "tr"

    days_block = _format_days(route)
    events_block = _format_events(request.available_events)

    fav = ", ".join(prefs.favorite_categories) if prefs.favorite_categories else "(none)"
    system = f"""You are a travel event recommender. Given a route itinerary and user preferences, select the most relevant events and explain why.

Route: {route.destination}, {route.total_days} days
Start date: {route.start_date or "unknown"}
Days:
{days_block}

User preferences:
- Travel style: {prefs.travel_style or "unknown"}
- Interests (favorite categories): {fav}
- Event interest: {prefs.event_interest or "none"}

Available events:
{events_block}

Instructions:
- Select up to 5 most relevant events
- Match events to route days based on date and geographic/thematic proximity
- Score relevance 0.0 to 1.0
- Write a short personalized message (1-2 sentences) in {lang} language
- Respond ONLY with JSON:
{{
  "message": "...",
  "recommended_events": [
    {{"event_id": "...", "matched_day": 2, "match_reason": "...", "relevance_score": 0.85}}
  ]
}}"""

    human = "Return only the JSON object, no other text."

    try:
        llm = create_chat_model(settings)
        resp = await llm.ainvoke(
            [SystemMessage(content=system), HumanMessage(content=human)]
        )
        raw = str(resp.content).strip()
        data = _extract_json_object(raw)
        if not data:
            logger.warning("Event recommendation: failed to parse JSON from LLM")
            return _fallback_all_events(request)

        try:
            parsed = EventRecommendResponse.model_validate(data)
        except ValidationError as ve:
            logger.warning("Event recommendation: invalid schema: %s", ve)
            return _fallback_all_events(request)

        if not parsed.message.strip():
            parsed = EventRecommendResponse(
                message=FALLBACK_MESSAGE_TR, recommended_events=parsed.recommended_events
            )

        # Validate matched_day is within route bounds; clear invalid values so
        # the frontend doesn't show events pinned to non-existent days.
        total_days = request.route_summary.total_days or 1
        for evt in parsed.recommended_events:
            if evt.matched_day is not None and not (1 <= evt.matched_day <= total_days):
                logger.warning(
                    "Event %s has matched_day=%d outside route range [1, %d] — clearing",
                    evt.event_id, evt.matched_day, total_days,
                )
                evt.matched_day = None

        return parsed
    except Exception as e:
        logger.warning("Event recommendation LLM error: %s", e)
        return _fallback_all_events(request)
