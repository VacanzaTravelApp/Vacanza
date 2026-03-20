"""Embedding service using OpenAI text-embedding-3-small."""

from __future__ import annotations

import logging
from typing import TYPE_CHECKING

from openai import APIConnectionError, APIError, RateLimitError
from openai import OpenAI
from tenacity import retry, retry_if_exception_type, stop_after_attempt, wait_exponential

if TYPE_CHECKING:
    from app.core.config import Settings

logger = logging.getLogger(__name__)

EMBEDDING_MODEL = "text-embedding-3-small"
EMBEDDING_DIM = 1536


class EmbeddingServiceError(Exception):
    """Raised when embedding generation fails."""

    pass


class EmbeddingService:
    """Produces text embeddings via OpenAI API."""

    def __init__(self, api_key: str, model: str = EMBEDDING_MODEL) -> None:
        if not api_key:
            raise EmbeddingServiceError("OpenAI API key is required for embeddings")
        self._client = OpenAI(api_key=api_key)
        self._model = model

    @retry(
        retry=retry_if_exception_type((RateLimitError, APIConnectionError, APIError)),
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        reraise=True,
    )
    def embed(self, text: str) -> list[float]:
        """Generate embedding for a single text.

        Args:
            text: Input text to embed.

        Returns:
            List of 1536 floats (embedding vector).

        Raises:
            EmbeddingServiceError: If API key missing, API error, or invalid response.
        """
        if not text or not text.strip():
            raise EmbeddingServiceError("Text cannot be empty")

        try:
            response = self._client.embeddings.create(
                input=text.strip(),
                model=self._model,
            )
        except (RateLimitError, APIConnectionError, APIError) as e:
            logger.warning("Embedding API error (retryable): %s", e)
            raise
        except Exception as e:
            logger.warning("Embedding API error: %s", e)
            raise EmbeddingServiceError(f"Embedding API failed: {e}") from e

        if not response.data:
            raise EmbeddingServiceError("Empty embedding response")

        embedding = response.data[0].embedding
        if len(embedding) != EMBEDDING_DIM:
            raise EmbeddingServiceError(
                f"Unexpected embedding size: {len(embedding)}, expected {EMBEDDING_DIM}"
            )
        return embedding

    @retry(
        retry=retry_if_exception_type((RateLimitError, APIConnectionError, APIError)),
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        reraise=True,
    )
    def embed_batch(self, texts: list[str]) -> list[list[float]]:
        """Generate embeddings for multiple texts (batched, more efficient).

        Args:
            texts: List of input texts.

        Returns:
            List of embedding vectors.

        Raises:
            EmbeddingServiceError: If API key missing, API error, or invalid response.
        """
        if not texts:
            return []

        # Filter empty strings
        cleaned = [t.strip() for t in texts if t and t.strip()]
        if not cleaned:
            raise EmbeddingServiceError("No valid texts to embed")

        try:
            response = self._client.embeddings.create(
                input=cleaned,
                model=self._model,
            )
        except (RateLimitError, APIConnectionError, APIError) as e:
            logger.warning("Embedding batch API error (retryable): %s", e)
            raise
        except Exception as e:
            logger.warning("Embedding batch API error: %s", e)
            raise EmbeddingServiceError(f"Embedding API failed: {e}") from e

        if len(response.data) != len(cleaned):
            raise EmbeddingServiceError(
                f"Response count mismatch: got {len(response.data)}, expected {len(cleaned)}"
            )

        embeddings = [d.embedding for d in sorted(response.data, key=lambda x: x.index)]
        for emb in embeddings:
            if len(emb) != EMBEDDING_DIM:
                raise EmbeddingServiceError(
                    f"Unexpected embedding size: {len(emb)}, expected {EMBEDDING_DIM}"
                )
        return embeddings


def create_embedding_service(settings: "Settings") -> EmbeddingService | None:
    """Create EmbeddingService if API key is configured.

    Returns:
        EmbeddingService instance or None if API key missing.
    """
    if not settings.openai_api_key:
        return None
    return EmbeddingService(api_key=settings.openai_api_key, model=EMBEDDING_MODEL)
