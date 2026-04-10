-- Similarity search RPC functions.
-- Call these from n8n via the Supabase "Custom Query" or HTTP Request node,
-- or directly from the Supabase SQL editor.


-- search_similar_records
-- Returns the top match_count records ranked by cosine similarity to the
-- provided query embedding. Optionally filter to a specific SF object type.
--
-- Example call from n8n (Supabase RPC node):
--   function: search_similar_records
--   params:   { query_embedding: [...], object_type: "Account", match_count: 10 }
CREATE OR REPLACE FUNCTION search_similar_records(
    query_embedding  vector(1536),
    object_type      VARCHAR(100) DEFAULT NULL,
    match_threshold  FLOAT        DEFAULT 0.75,
    match_count      INT          DEFAULT 10
)
RETURNS TABLE (
    sf_record_id    VARCHAR(18),
    sf_object_type  VARCHAR(100),
    sf_fields       JSONB,
    source_text     TEXT,
    similarity      FLOAT
)
LANGUAGE SQL STABLE AS $$
    SELECT
        o.sf_record_id,
        o.sf_object_type,
        o.sf_fields,
        o.source_text,
        1 - (e.embedding <=> query_embedding) AS similarity
    FROM sf_embeddings e
    JOIN sf_objects o ON o.id = e.sf_object_id
    WHERE
        o.is_deleted = FALSE
        AND (object_type IS NULL OR o.sf_object_type = object_type)
        AND 1 - (e.embedding <=> query_embedding) >= match_threshold
    ORDER BY e.embedding <=> query_embedding
    LIMIT match_count;
$$;


-- find_near_duplicates
-- Surfaces pairs of records within the same object type whose embeddings are
-- very similar (default threshold 0.97). Use this from a scheduled n8n QA
-- workflow to flag potential duplicate Salesforce records.
--
-- Note: this is an O(n²) scan — run on subsets or during off-peak hours
-- for large tables. For very large tables consider running per-batch.
CREATE OR REPLACE FUNCTION find_near_duplicates(
    object_type          VARCHAR(100),
    similarity_threshold FLOAT DEFAULT 0.97
)
RETURNS TABLE (
    record_id_a  VARCHAR(18),
    record_id_b  VARCHAR(18),
    similarity   FLOAT
)
LANGUAGE SQL STABLE AS $$
    SELECT
        o1.sf_record_id AS record_id_a,
        o2.sf_record_id AS record_id_b,
        1 - (e1.embedding <=> e2.embedding) AS similarity
    FROM sf_embeddings e1
    JOIN sf_embeddings e2 ON e1.id < e2.id  -- avoids self-pairs and duplicate pairs
    JOIN sf_objects o1 ON o1.id = e1.sf_object_id
    JOIN sf_objects o2 ON o2.id = e2.sf_object_id
    WHERE
        o1.sf_object_type = object_type
        AND o2.sf_object_type = object_type
        AND o1.is_deleted = FALSE
        AND o2.is_deleted = FALSE
        AND 1 - (e1.embedding <=> e2.embedding) >= similarity_threshold
    ORDER BY similarity DESC;
$$;
