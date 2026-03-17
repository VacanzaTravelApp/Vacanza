"""Application configuration via Pydantic Settings."""

from pydantic import computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # OpenAI
    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"

    # Database — set DATABASE_URL in .env for your server
    database_url: str | None = None
    db_host: str = "localhost"
    db_port: int = 5432
    db_name: str = "vacanza_ai"
    db_user: str = "vacanza"
    db_password: str = "vacanza"

    # Server
    app_host: str = "0.0.0.0"
    app_port: int = 8000
    debug: bool = False

    # Backend internal tool executor (agentic POI search)
    backend_internal_url: str = "http://localhost:8080"

    @computed_field
    @property
    def database_url_resolved(self) -> str:
        """Resolved database URL: DATABASE_URL if set, else built from DB_* vars."""
        if self.database_url:
            return self.database_url
        return (
            f"postgresql://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )


def get_settings() -> Settings:
    """Returns application settings instance."""
    return Settings()
