"""Content moderation using OpenAI Moderation API.

Blocks harmful, illegal, or policy-violating user input before it reaches the LLM.
API is public-facing; moderation is critical for safety.
"""

import logging

from openai import AsyncOpenAI

from app.core.config import Settings

logger = logging.getLogger(__name__)

# Generic refusal shown to user when content is blocked (no details about why)
REFUSAL_MESSAGE = (
    "I can't help with that. I'm VacanzaBot, here for travel planning. "
    "Ask about destinations, tips, or trip ideas."
)


async def is_content_flagged(settings: Settings, text: str) -> tuple[bool, list[str]]:
    """Check if user content violates safety policies using OpenAI Moderation API.

    Args:
        settings: Application settings (uses openai_api_key).
        text: User message to check.

    Returns:
        Tuple of (is_flagged: bool, flagged_categories: list[str]).
        If API fails, returns (False, []) to avoid blocking legitimate users.
    """
    if not settings.openai_api_key or not text or not text.strip():
        return False, []

    try:
        client = AsyncOpenAI(api_key=settings.openai_api_key)
        response = await client.moderations.create(
            input=text.strip(),
            model="omni-moderation-latest",  # text-moderation-latest deprecated; omni supports text+image
        )
        result = response.results[0] if response.results else None
        if not result:
            return False, []

        if not result.flagged:
            return False, []

        # Collect which categories were flagged (for logging)
        cats = result.categories
        if hasattr(cats, "model_dump"):
            flagged = [k for k, v in cats.model_dump().items() if v]
        elif isinstance(cats, dict):
            flagged = [k for k, v in cats.items() if v]
        else:
            flagged = []
        return True, flagged
    except Exception as e:
        logger.warning("Moderation API failed (non-blocking): %s", e)
        return False, []
