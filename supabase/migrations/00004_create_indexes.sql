-- HNSW similarity search index on the embedding column.
--
-- HNSW (Hierarchical Navigable Small World) is the right default for most
-- Salesforce dataset sizes (up to ~1M rows). It gives low query latency with
-- high recall and requires no upfront knowledge of the data distribution.
--
-- Tuning parameters:
--   m              = max connections per layer (higher = better recall, more memory)
--   ef_construction = search width during build (higher = better recall, slower build)
--
-- If your dataset exceeds ~1M rows and build time becomes a bottleneck,
-- switch to the IVFFlat option below instead.
CREATE INDEX idx_embeddings_hnsw ON sf_embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- IVFFlat alternative for very large datasets (>1M rows).
-- Faster to build, lower memory footprint, but requires a VACUUM ANALYZE
-- after bulk inserts and needs lists = sqrt(row_count) tuned periodically.
-- Uncomment and drop the HNSW index above if switching.
--
-- CREATE INDEX idx_embeddings_ivfflat ON sf_embeddings
--     USING ivfflat (embedding vector_cosine_ops)
--     WITH (lists = 100);
