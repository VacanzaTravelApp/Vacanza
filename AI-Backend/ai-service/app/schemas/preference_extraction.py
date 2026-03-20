"""Schemas for AI preference extraction from chat conversations."""

from pydantic import BaseModel, Field


class ExtractedPreference(BaseModel):
    """A single user preference extracted from conversation."""

    preference_key: str = Field(
        ...,
        description="Preference category key. Examples: cuisine_preference, "
        "activity_level, travel_style, budget_preference, "
        "accommodation_preference, climate_preference, "
        "cultural_interest, transport_preference, "
        "dietary_restriction, language_preference, "
        "destination_preference, trip_pace",
    )
    preference_value: str = Field(
        ...,
        description="The extracted preference value. Be concise but specific. "
        "Examples: 'Italian, Turkish', 'HIGH', 'ADVENTURE', 'prefers hostels'",
    )
    confidence: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="How confident you are about this preference (0.0-1.0). "
        "1.0 = user explicitly stated it, 0.5 = inferred from context",
    )


class PreferenceExtractionResult(BaseModel):
    """Result of preference extraction from a conversation turn."""

    preferences: list[ExtractedPreference] = Field(
        default_factory=list,
        description="List of extracted preferences. Empty if no preferences detected.",
    )
