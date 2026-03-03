"""Chat service with LangChain and context memory (sliding window)."""

import asyncio
import logging
import uuid

from langchain_core.messages import AIMessage, HumanMessage, SystemMessage

from app.core.config import Settings
from app.schemas.chat import UserProfileForAi
from app.schemas.preference_extraction import PreferenceExtractionResult
from app.db.models import Message
from app.repositories import ConversationRepository, MessageEmbeddingRepository, MessageRepository
from app.services.embedding_service import EMBEDDING_MODEL, EmbeddingServiceError, create_embedding_service
from app.services.openai_service import create_chat_model
from app.services.preference_extraction_service import extract_preferences

logger = logging.getLogger(__name__)

MEMORY_WINDOW = 10  # Last N user+assistant pairs for context
RAG_TOP_K = 8  # Max similar old messages (5-10 range for token limit)
RAG_MAX_CHARS_PER_MSG = 250  # Truncate to avoid token overflow (~80 tokens/msg)


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


def _confidence_label(confidence: float) -> str:
    """Human-readable confidence label (optional display)."""
    if confidence >= 0.8:
        return "high"
    if confidence >= 0.5:
        return "medium"
    return "low"


def _build_ai_preferences_prompt(
    existing_preferences: list[dict] | None,
    include_confidence: bool = True,
) -> str:
    """Build AI-inferred preferences section for system prompt (from user_preferences_ai)."""
    if not existing_preferences:
        return ""
    lines = ["User preferences (learned from chat and behavior — use these in your recommendations):"]
    for p in existing_preferences:
        key = p.get("preference_key") or ""
        value = p.get("preference_value") or ""
        conf = p.get("confidence")
        if not key or not value:
            continue
        if include_confidence and conf is not None:
            label = _confidence_label(float(conf))
            lines.append(f"- {key}: {value} (confidence: {label})")
        else:
            lines.append(f"- {key}: {value}")
    if len(lines) <= 1:
        return ""
    return "\n".join(lines)


def _build_profile_prompt(profile: UserProfileForAi | None) -> str:
    """Build user profile section for system prompt. Includes name, country, budget and behavioral instructions."""
    if not profile:
        return ""
    parts: list[str] = []
    if profile.displayName:
        parts.append(f"Name: {profile.displayName}")
    if profile.firstName and not profile.displayName:
        parts.append(f"First name: {profile.firstName}")
    if profile.middleName:
        parts.append(f"Middle name: {profile.middleName}")
    if profile.lastName:
        parts.append(f"Last name: {profile.lastName}")
    if profile.preferredName:
        parts.append(f"Preferred name: {profile.preferredName}")
    if profile.country:
        parts.append(f"Country: {profile.country}")
    if profile.birthDate:
        parts.append(f"Birth date: {profile.birthDate}")
    if profile.gender:
        parts.append(f"Gender: {profile.gender}")
    if profile.budget:
        parts.append(f"Budget: {profile.budget}")
    if profile.joinDate:
        parts.append(f"Join date: {profile.joinDate}")
    if not parts:
        return ""

    instructions: list[str] = []
    if profile.displayName or profile.preferredName or profile.firstName:
        name = profile.displayName or profile.preferredName or profile.firstName
        instructions.append(f"Greet the user by name ({name}).")
    if profile.budget:
        instructions.append("Consider budget (Budget: " + profile.budget + ") in your recommendations.")
    if profile.country:
        instructions.append("Use country (Country: " + profile.country + ") in your recommendations.")

    result = "User profile: " + ", ".join(parts) + ".\n"
    if instructions:
        result += "Rules: " + " ".join(instructions)
    return result


def _build_rag_context_prompt(similar_messages: list[tuple[str, str]]) -> str:
    """Build 'Previous conversation notes' section for system/context.

    Token limit: max RAG_TOP_K messages, each truncated to RAG_MAX_CHARS_PER_MSG.
    """
    if not similar_messages:
        return ""
    lines = [
        "Relevant notes from previous conversations (use these in your response):"
    ]
    for role, content in similar_messages[:RAG_TOP_K]:
        truncated = (
            content[:RAG_MAX_CHARS_PER_MSG] + "..."
            if len(content) > RAG_MAX_CHARS_PER_MSG
            else content
        )
        prefix = "User" if role == "user" else "Assistant"
        lines.append(f"- {prefix}: {truncated}")
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
    user_profile: UserProfileForAi | None = None,
    existing_preferences: list[dict] | None = None,
) -> tuple[str, PreferenceExtractionResult]:
    """Send user message, get AI response with context, save both to DB.

    Returns:
        Tuple of (AI response content, extracted preferences).
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
    profile_prompt = _build_profile_prompt(user_profile)
    ai_prefs_prompt = _build_ai_preferences_prompt(existing_preferences, include_confidence=True)
    rag_prompt = _build_rag_context_prompt(rag_messages)
    # Dynamic system prompt: Vacanza definition + role + profile + AI preferences + RAG
    base_prompt = """You are the travel assistant for Vacanza, a personal app for vacation and travel planning.

Use a warm, friendly tone. Talk as if you know the user—like a trusted friend. Avoid formal or corporate language; be simple, clear, and personable. When giving destination suggestions, budget-friendly options, or travel tips, consider the user's preferences.

Always respond in the same language the user writes in."""
    system_parts = [base_prompt]
    if profile_prompt:
        system_parts.append(profile_prompt.strip())
    if ai_prefs_prompt:
        system_parts.append(ai_prefs_prompt)
    if rag_prompt:
        system_parts.append(rag_prompt)
        system_parts.append("Use these previous conversation notes when responding to the current chat.")
    llm_messages.append(SystemMessage(content="\n\n".join(filter(None, system_parts))))
    llm_messages.extend(history)
    llm_messages.append(HumanMessage(content=user_content))

    # Invoke LLM
    llm = create_chat_model(settings)
    response = await llm.ainvoke(llm_messages)
    ai_content = str(response.content)

    # Save messages + extract preferences concurrently
    user_msg = message_repo.create(
        conversation_id=conversation_id,
        role="user",
        content=user_content,
    )
    assistant_msg = message_repo.create(
        conversation_id=conversation_id,
        role="assistant",
        content=ai_content,
    )

    embedding_user_task = _save_embedding_for_message(
        settings, message_embedding_repo, user_msg, user_content, user_id
    )
    embedding_assistant_task = _save_embedding_for_message(
        settings, message_embedding_repo, assistant_msg, ai_content, user_id
    )
    extraction_task = extract_preferences(
        settings, user_content, ai_content, existing_preferences=existing_preferences
    )

    _, _, extraction_result = await asyncio.gather(
        embedding_user_task, embedding_assistant_task, extraction_task
    )

    return ai_content, extraction_result
