-- HNSW index for fast cosine similarity search on embeddings.
CREATE INDEX ON qa_prompts
    USING hnsw (embedding vector_cosine_ops);
