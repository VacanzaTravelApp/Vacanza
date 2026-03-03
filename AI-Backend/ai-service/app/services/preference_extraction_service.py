"""Extract user preferences from chat conversations using LLM structured output."""

import logging

from langchain_core.messages import HumanMessage, SystemMessage

from app.core.config import Settings
from app.schemas.preference_extraction import PreferenceExtractionResult
from app.services.openai_service import create_chat_model

logger = logging.getLogger(__name__)

EXTRACTION_SYSTEM_PROMPT = """You are a preference extraction engine for Vacanza, a travel planning app.

Analyze the conversation between a user and the travel assistant. Extract any user preferences that are explicitly stated or strongly implied.

Focus on these preference categories:
- cuisine_preference: Food and dining preferences
- activity_level: LOW, MODERATE, HIGH
- travel_style: ADVENTURE, RELAXATION, CULTURAL, BACKPACKER, LUXURY, FAMILY
- budget_preference: BUDGET, MID_RANGE, LUXURY
- accommodation_preference: Hotel, hostel, Airbnb, resort, camping, etc.
- climate_preference: TROPICAL, WARM, COLD, MILD, DRY
- cultural_interest: Museums, history, art, architecture, nightlife, etc.
- transport_preference: FLY, TRAIN, DRIVE, PUBLIC_TRANSIT, WALK
- dietary_restriction: Vegan, vegetarian, halal, kosher, gluten-free, etc.
- health_condition: Allergies (pollen, dust, sun, etc.), motion sickness, mobility issues, chronic conditions relevant to travel
- language_preference: Languages the user prefers to communicate in
- destination_preference: Preferred destinations, regions, or countries
- trip_pace: RELAXED, MODERATE, PACKED
- travel_season: Preferred travel months or seasons
- companion_preference: Solo, couple, family, group

Rules:
- Only extract preferences you are confident about from THIS conversation turn.
- Set confidence to 1.0 for explicitly stated preferences ("I love Italian food", "I have pollen allergy").
- Set confidence to 0.6-0.8 for strongly implied preferences ("That pasta place sounds great!").
- Do NOT extract preferences below 0.5 confidence.
- Return an empty list if no preferences are detected in this turn.
- Be concise in preference_value.

CRITICAL — Merging with existing preferences:
- If existing preferences are provided below, use them as context.
- For ADDITIVE preferences (allergies, cuisines, interests, dietary restrictions, destinations, languages): MERGE the new value with the existing one. Example: existing "peanut allergy" + user says "I also have shellfish allergy" → return "peanut allergy, shellfish allergy" as a single combined value for the SAME key.
- For SINGLE-VALUE preferences (activity_level, budget, trip_pace, travel_style, climate): REPLACE the old value with the new one.
- If the user REMOVES a specific item ("I no longer have peanut allergy"), return the remaining items. Example: existing "peanut allergy, shellfish allergy" + user says "peanut allergy is gone" → return "shellfish allergy".
- If the user NEGATES everything ("I have no allergies at all"), return "none" for that key.
- Always use the SAME preference_key so the old value gets overwritten with the merged result."""


def _build_existing_preferences_context(
    existing_preferences: list[dict] | None,
) -> str:
    """Build a context block showing what we already know about the user."""
    if not existing_preferences:
        return ""
    lines = ["Current known preferences for this user:"]
    for p in existing_preferences:
        lines.append(f"- {p['preference_key']}: {p['preference_value']} (confidence: {p['confidence']})")
    return "\n".join(lines)


async def extract_preferences(
    settings: Settings,
    user_message: str,
    ai_response: str,
    existing_preferences: list[dict] | None = None,
) -> PreferenceExtractionResult:
    """Extract user preferences from a single conversation turn.

    Uses LLM structured output (Pydantic) to ensure valid schema.
    Runs as a lightweight secondary call after the main chat response.

    Args:
        existing_preferences: Optional list of dicts with keys
            preference_key, preference_value, confidence — used as
            context so the LLM can detect corrections/updates.
    """
    try:
        llm = create_chat_model(settings)
        structured_llm = llm.with_structured_output(PreferenceExtractionResult)

        existing_ctx = _build_existing_preferences_context(existing_preferences)
        user_prompt_parts = []
        if existing_ctx:
            user_prompt_parts.append(existing_ctx)
        user_prompt_parts.append(f"User message: {user_message}")
        user_prompt_parts.append(f"Assistant response: {ai_response}")
        user_prompt_parts.append(
            "Extract any user preferences from the user's message above. "
            "For list-type preferences (allergies, cuisines, interests, etc.), "
            "MERGE new values with existing ones — do not discard the old values. "
            "If the user corrects or negates an existing preference, return the updated value."
        )

        messages = [
            SystemMessage(content=EXTRACTION_SYSTEM_PROMPT),
            HumanMessage(content="\n\n".join(user_prompt_parts)),
        ]

        result = await structured_llm.ainvoke(messages)
        if result and result.preferences:
            logger.info(
                "Extracted %d preferences: %s",
                len(result.preferences),
                [(p.preference_key, p.preference_value, p.confidence) for p in result.preferences],
            )
        return result or PreferenceExtractionResult(preferences=[])

    except Exception as e:
        logger.warning("Preference extraction failed (non-blocking): %s", e)
        return PreferenceExtractionResult(preferences=[])
