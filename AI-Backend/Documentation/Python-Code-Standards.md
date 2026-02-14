# Vacanza Python AI Service — Code Standards

This document defines the code standards for the Python microservice in the `ai-service/` directory.

---

## 1. General Principles

- **PEP 8** is used as the primary style guide.
- **Type hints** are required for all public functions and methods.
- **Docstrings** must be present for all modules, classes, and public functions.
- Code should follow **DRY** (Don't Repeat Yourself) and **SOLID** principles.

---

## 2. Project Structure

```
ai-service/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application entry point
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes/
│   │   │   ├── __init__.py
│   │   │   ├── health.py
│   │   │   └── ai.py
│   │   └── deps.py          # Dependency injection
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py        # Pydantic Settings
│   │   └── logging.py
│   ├── services/
│   │   ├── __init__.py
│   │   └── openai_service.py
│   └── schemas/
│       ├── __init__.py
│       └── requests.py
├── tests/
├── requirements.txt
├── Dockerfile
├── .env.example
└── pyproject.toml / .flake8
```

---

## 3. Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Modules | `snake_case` | `openai_service.py` |
| Classes | `PascalCase` | `OpenAIService` |
| Functions/Methods | `snake_case` | `get_embedding()` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_RETRIES` |
| Private | `_leading_underscore` | `_validate_token()` |

---

## 4. Import Ordering

1. Standard library (alphabetical)
2. Third-party (alphabetical)
3. Local / app imports (alphabetical)

Separate groups with blank lines.

```python
import os
from typing import Optional

from fastapi import APIRouter, Depends
from langchain_openai import ChatOpenAI

from app.core.config import settings
from app.schemas.requests import ChatRequest
```

---

## 5. Type Hints

- Parameter and return types must be specified for all public APIs.
- Prefer `T | None` over `Optional[T]` (Python 3.10+).
- Use Pydantic models for request/response schemas.

```python
def process_prompt(text: str, model: str = "gpt-4") -> dict[str, Any]:
    """Returns the processed prompt result."""
    ...
```

---

## 6. Docstring Format

Use **Google style** docstrings.

```python
def chat_completion(messages: list[dict], temperature: float = 0.7) -> str:
    """Performs an OpenAI Chat Completion call.

    Args:
        messages: List of messages (role + content format).
        temperature: Model creativity parameter (0-2).

    Returns:
        Model response text.

    Raises:
        OpenAIError: When the API call fails.
    """
    ...
```

---

## 7. Error Handling

- Custom exception classes should be defined in `app/core/exceptions.py`.
- API errors must return appropriate HTTP status codes.
- Sensitive information (API keys, tokens, etc.) must not be logged.

```python
# Good
raise HTTPException(status_code=503, detail="OpenAI service unavailable")

# Bad
raise Exception(f"API key invalid: {api_key}")
```

---

## 8. Environment and Configuration

- All configuration is managed via **Pydantic Settings**.
- `.env` must be in `.gitignore`; provide `.env.example` as a template.
- Sensitive values must be read from environment variables.

```python
# app/core/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    openai_api_key: str
    openai_model: str = "gpt-4o-mini"
    
    class Config:
        env_file = ".env"
```

---

## 9. Logging

- Use `structlog` or standard `logging`.
- Log levels: `DEBUG`, `INFO`, `WARNING`, `ERROR`.
- In production, use `INFO` or higher.
- Consider adding request ID or correlation ID.

---

## 10. Test Standards

- Use **pytest**.
- Test files should follow `test_*.py` or `*_test.py` naming.
- Use mocks for external API calls.
- Minimum coverage target: 80%.

```python
# tests/test_health.py
def test_health_returns_200(client: TestClient) -> None:
    """Health endpoint should return 200."""
    response = client.get("/health")
    assert response.status_code == 200
```

---

## 11. Security

- API keys must never be hardcoded.
- Consider rate limiting.
- CORS settings should be strict for production.
- Input validation must always be done with Pydantic.

---

## 12. Tooling

| Tool | Purpose |
|------|---------|
| **ruff** / **flake8** | Linting |
| **black** | Formatting |
| **mypy** | Static type checking |
| **pytest** | Unit/integration tests |
| **pre-commit** | Pre-commit checks (optional) |

---

## 13. Versioning and Dependencies

- `requirements.txt` should contain pinned versions.
- Use `pip freeze` or `pip-tools` when adding new dependencies.
- Target Python 3.11+.

---

*Last updated: February 2025*
