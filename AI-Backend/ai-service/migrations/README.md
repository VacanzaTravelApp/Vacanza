# Migrations

SQL scripts run in alphabetical order. **Migrations run automatically on application startup** (like Spring Boot Flyway).

- **Docker init:** For new containers, scripts also run via `/docker-entrypoint-initdb.d/` on first DB creation.
- **App startup:** The AI service runs all `*.sql` files in this folder when it starts.

- `001_enable_pgvector.sql` — Enables the pgvector extension for vector similarity search.
- `002_create_conversations_messages_embeddings.sql` — Creates `conversations`, `messages`, and `message_embeddings` tables.
- `003_add_user_id_to_message_embeddings.sql` — Adds `user_id` to `message_embeddings` for efficient RAG queries (filter by user).