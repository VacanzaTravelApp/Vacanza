"""OpenAI service using LangChain."""

from langchain_openai import ChatOpenAI

from app.core.config import Settings


def create_chat_model(settings: Settings, temperature: float = 0.0) -> ChatOpenAI:
    """Creates a LangChain ChatOpenAI instance from settings.

    Args:
        settings: Application settings containing OpenAI config.
        temperature: Sampling temperature (0 = deterministic, 0.3 = creative variety).

    Returns:
        Configured ChatOpenAI instance.
    """
    return ChatOpenAI(
        api_key=settings.openai_api_key,
        model=settings.openai_model,
        temperature=temperature,
        max_tokens=6000,
    )


async def test_connection(settings: Settings) -> tuple[bool, str]:
    """Tests the OpenAI API connection with a minimal prompt.

    Args:
        settings: Application settings containing OpenAI config.

    Returns:
        Tuple of (success: bool, message: str).
    """
    if not settings.openai_api_key:
        return False, "OPENAI_API_KEY is not set"

    try:
        llm = create_chat_model(settings)
        response = await llm.ainvoke("Reply with exactly: OK")
        return True, str(response.content).strip()
    except Exception as e:
        return False, str(e)
