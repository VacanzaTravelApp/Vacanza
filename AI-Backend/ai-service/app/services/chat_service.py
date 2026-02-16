"""Chat service with LangChain and context memory (sliding window)."""

import uuid

from langchain_core.messages import AIMessage, HumanMessage

from app.core.config import Settings
from app.db.models import Message
from app.repositories import MessageRepository
from app.services.openai_service import create_chat_model

MEMORY_WINDOW = 10  # Last N user+assistant pairs for context


def _build_context_messages(messages: list[Message]) -> list[HumanMessage | AIMessage]:
    """Build sliding window of messages for LLM context (ConversationBufferWindowMemory logic)."""
    pairs: list[tuple[str, str]] = []
    user_content: str | None = None

    for msg in messages:
        if msg.role == "user":
            user_content = msg.content
        elif msg.role == "assistant" and user_content is not None:
            pairs.append((user_content, msg.content))
            user_content = None

    # Keep only last k pairs
    window = pairs[-MEMORY_WINDOW:] if len(pairs) > MEMORY_WINDOW else pairs

    result: list[HumanMessage | AIMessage] = []
    for human, ai in window:
        result.append(HumanMessage(content=human))
        result.append(AIMessage(content=ai))
    return result


async def get_ai_response(
    settings: Settings,
    message_repo: MessageRepository,
    conversation_id: uuid.UUID,
    user_content: str,
) -> str:
    """Send user message, get AI response with context, save both to DB.

    Args:
        settings: App settings.
        message_repo: Message repository.
        conversation_id: Conversation ID.
        user_content: User message text.

    Returns:
        AI response content.
    """
    # Load conversation history from DB
    messages = message_repo.list_by_conversation(
        conversation_id=conversation_id,
        limit=MEMORY_WINDOW * 2 + 1,
    )

    # Build context (sliding window like ConversationBufferWindowMemory)
    history = _build_context_messages(list(messages))

    # Build full message list for LLM
    llm_messages: list[HumanMessage | AIMessage] = history + [HumanMessage(content=user_content)]

    # Invoke LLM
    llm = create_chat_model(settings)
    response = await llm.ainvoke(llm_messages)
    ai_content = str(response.content)

    # Save to DB
    message_repo.create(
        conversation_id=conversation_id,
        role="user",
        content=user_content,
    )
    message_repo.create(
        conversation_id=conversation_id,
        role="assistant",
        content=ai_content,
    )

    return ai_content
