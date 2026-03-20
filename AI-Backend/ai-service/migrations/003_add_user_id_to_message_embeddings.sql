-- Add user_id to message_embeddings for efficient RAG queries (filter by user)
-- user_id comes from conversation; denormalized for fast vector similarity search

ALTER TABLE message_embeddings
ADD COLUMN IF NOT EXISTS user_id UUID;

CREATE INDEX IF NOT EXISTS idx_message_embeddings_user_id ON message_embeddings(user_id);
