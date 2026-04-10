-- Q&A prompts table for RAG (Retrieval Augmented Generation).
-- n8n embeds a user question, calls match_qa_prompts(), and passes
-- the returned rows as context to the AI step.
CREATE TABLE qa_prompts (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    question    TEXT        NOT NULL,
    answer      TEXT        NOT NULL,
    category    TEXT,
    embedding   vector(1536),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
