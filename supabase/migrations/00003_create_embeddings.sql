-- Vector embeddings table.
-- Separated from sf_objects so embeddings can be regenerated (e.g. on model
-- upgrade) without touching the metadata audit trail.
--
-- vector(1536) matches OpenAI text-embedding-3-small.
-- If you switch to text-embedding-3-large, change to vector(3072) and
-- re-run your n8n backfill workflow.
CREATE TABLE sf_embeddings (
    id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    sf_object_id     UUID         NOT NULL REFERENCES sf_objects(id) ON DELETE CASCADE,
    embedding        vector(1536) NOT NULL,
    model_name       VARCHAR(100) NOT NULL,
    embed_input_hash VARCHAR(64)  NOT NULL,  -- SHA-256 of source_text; used for idempotency
    token_count      INTEGER,                -- tokens consumed (cost tracking)
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    quality_score    FLOAT,                  -- NULL until a QA workflow populates it
    needs_review     BOOLEAN      NOT NULL DEFAULT FALSE,
    review_notes     TEXT                    -- free-text annotations
);

-- One active embedding per SF object (latest upsert wins)
CREATE UNIQUE INDEX uq_sf_embeddings_object ON sf_embeddings (sf_object_id);

-- Partial index for records flagged for review (fast lookup by n8n QA workflow)
CREATE INDEX idx_sf_embeddings_needs_review ON sf_embeddings (sf_object_id)
    WHERE needs_review = TRUE;
