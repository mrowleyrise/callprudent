-- Similarity search function called by n8n via Supabase RPC.
-- Returns the top match_count Q&A pairs most similar to the query embedding.
--
-- n8n usage: Supabase node → RPC → match_qa_prompts
-- Params: { query_embedding: [...], match_threshold: 0.5, match_count: 5 }
CREATE OR REPLACE FUNCTION match_qa_prompts(
    query_embedding  vector(1536),
    match_threshold  float DEFAULT 0.5,
    match_count      int   DEFAULT 5
)
RETURNS TABLE (
    id          UUID,
    question    TEXT,
    answer      TEXT,
    category    TEXT,
    similarity  float
)
LANGUAGE SQL STABLE AS $$
    SELECT
        id,
        question,
        answer,
        category,
        1 - (embedding <=> query_embedding) AS similarity
    FROM qa_prompts
    WHERE 1 - (embedding <=> query_embedding) > match_threshold
    ORDER BY embedding <=> query_embedding
    LIMIT match_count;
$$;
