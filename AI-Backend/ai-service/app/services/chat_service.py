"""Chat service with LangChain and context memory (sliding window)."""

import asyncio
import logging
import uuid

from langchain_core.messages import AIMessage, HumanMessage, SystemMessage

from app.core.config import Settings
from app.db.models import Message
from app.repositories import ConversationRepository, MessageEmbeddingRepository, MessageRepository
from app.services.embedding_service import EMBEDDING_MODEL, EmbeddingServiceError, create_embedding_service
from app.services.openai_service import create_chat_model

logger = logging.getLogger(__name__)

MEMORY_WINDOW = 10  # Last N user+assistant pairs for context
RAG_TOP_K = 8  # Max similar old messages to add as context


async def _save_embedding_for_message(
    settings: Settings,
    message_embedding_repo: MessageEmbeddingRepository,
    message: Message,
    content: str,
    user_id: uuid.UUID | None,
) -> None:
    """Create and save embedding for a message. Logs on failure, does not raise."""
    if not content or not content.strip():
        return
    embedding_service = create_embedding_service(settings)
    if not embedding_service:
        return
    try:
        embedding = await asyncio.to_thread(embedding_service.embed, content.strip())
        message_embedding_repo.create(
            message_id=message.id,
            embedding=embedding,
            model=EMBEDDING_MODEL,
            user_id=user_id,
        )
    except EmbeddingServiceError as e:
        logger.warning("Embedding failed for message %s: %s", message.id, e)
    except Exception as e:
        logger.warning("Embedding failed for message %s: %s", message.id, e)


def _build_rag_context_prompt(similar_messages: list[tuple[str, str]]) -> str:
    """Build 'Önceki konuşma notları' section for system/context."""
    if not similar_messages:
        return ""
    lines = ["Önceki konuşmalardan ilgili notlar:"]
    for role, content in similar_messages:
        prefix = "Kullanıcı" if role == "user" else "Asistan"
        lines.append(f"- {prefix}: {content[:200]}{'...' if len(content) > 200 else ''}")
    return "\n".join(lines)


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
    message_embedding_repo: MessageEmbeddingRepository,
    conversation_repo: ConversationRepository,
    conversation_id: uuid.UUID,
    user_content: str,
) -> str:
    """Send user message, get AI response with context, save both to DB.

    Args:
        settings: App settings.
        message_repo: Message repository.
        message_embedding_repo: Message embedding repository.
        conversation_repo: Conversation repository (for user_id).
        conversation_id: Conversation ID.
        user_content: User message text.

    Returns:
        AI response content.
    """
    conversation = conversation_repo.get_by_id(conversation_id)
    user_id = conversation.user_id if conversation else None

    # RAG: find similar old messages for long-term context
    rag_messages: list[tuple[str, str]] = []
    embedding_service = create_embedding_service(settings)
    if embedding_service and user_id:
        try:
            query_embedding = await asyncio.to_thread(
                embedding_service.embed, user_content.strip()
            )
            similar = message_embedding_repo.search_similar(
                query_embedding=query_embedding,
                user_id=user_id,
                exclude_conversation_id=conversation_id,
                limit=RAG_TOP_K,
            )
            for me in similar:
                if me.message:
                    rag_messages.append((me.message.role, me.message.content))
        except (EmbeddingServiceError, Exception) as e:
            logger.debug("RAG search skipped: %s", e)

    # Load conversation history from DB
    messages = message_repo.list_by_conversation(
        conversation_id=conversation_id,
        limit=MEMORY_WINDOW * 2 + 1,
    )

    # Build context (sliding window like ConversationBufferWindowMemory)
    history = _build_context_messages(list(messages))

    # Build full message list for LLM
    llm_messages: list[SystemMessage | HumanMessage | AIMessage] = []
    rag_prompt = _build_rag_context_prompt(rag_messages)
    if rag_prompt:
        llm_messages.append(
            SystemMessage(
                content=f"Sen Vacanza seyahat asistanısın. {rag_prompt}\n\nMevcut sohbete yanıt ver."
            )
        )
    llm_messages.extend(history)
    llm_messages.append(HumanMessage(content=user_content))

    # Invoke LLM
    llm = create_chat_model(settings)
    response = await llm.ainvoke(llm_messages)
    ai_content = str(response.content)

    # Save user message to DB
    user_msg = message_repo.create(
        conversation_id=conversation_id,
        role="user",
        content=user_content,
    )
    await _save_embedding_for_message(
        settings, message_embedding_repo, user_msg, user_content, user_id
    )

    # Save assistant message to DB
    assistant_msg = message_repo.create(
        conversation_id=conversation_id,
        role="assistant",
        content=ai_content,
    )
    await _save_embedding_for_message(
        settings, message_embedding_repo, assistant_msg, ai_content, user_id
    )

    return ai_content
