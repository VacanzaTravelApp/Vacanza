"""AI endpoint tests."""

from unittest.mock import AsyncMock, patch

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


@patch("app.api.routes.ai.test_connection", new_callable=AsyncMock)
def test_openai_test_success(mock_test: AsyncMock) -> None:
    """Test endpoint returns 200 when OpenAI connection succeeds."""
    mock_test.return_value = (True, "OK")
    response = client.get("/ai/test")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "message": "OK"}


@patch("app.api.routes.ai.test_connection", new_callable=AsyncMock)
def test_openai_test_failure(mock_test: AsyncMock) -> None:
    """Test endpoint returns 503 when OpenAI connection fails."""
    mock_test.return_value = (False, "API key invalid")
    response = client.get("/ai/test")
    assert response.status_code == 503
