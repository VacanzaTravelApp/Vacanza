-- Add title to conversations for display in chat session list
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS title VARCHAR(120);
