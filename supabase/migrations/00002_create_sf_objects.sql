-- Salesforce record metadata table.
-- Stores one row per Salesforce record, capturing the field snapshot and the
-- exact source_text string that was sent to OpenAI. Keeping source_text here
-- (not in sf_embeddings) means you can re-embed without losing the audit trail.
CREATE TABLE sf_objects (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    sf_record_id    VARCHAR(18) NOT NULL,
    sf_object_type  VARCHAR(100) NOT NULL,
    sf_fields       JSONB       NOT NULL,
    source_text     TEXT        NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_synced_at  TIMESTAMPTZ,
    is_deleted      BOOLEAN     NOT NULL DEFAULT FALSE,

    CONSTRAINT uq_sf_record UNIQUE (sf_record_id, sf_object_type)
);

-- n8n upsert target: ON CONFLICT (sf_record_id, sf_object_type) DO UPDATE
CREATE INDEX idx_sf_objects_type   ON sf_objects (sf_object_type) WHERE is_deleted = FALSE;
CREATE INDEX idx_sf_objects_synced ON sf_objects (last_synced_at DESC);

-- Auto-update updated_at on any row change
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sf_objects_updated_at
    BEFORE UPDATE ON sf_objects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
