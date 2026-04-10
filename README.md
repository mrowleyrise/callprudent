# callprudent — Supabase Vector Schema

This repo is the authoritative, git-managed source for the Supabase pgvector schema used to store Salesforce record embeddings. The ETL pipeline (Salesforce → OpenAI → Supabase) runs entirely in n8n; this repo only manages the database layer.

## Structure

```
supabase/
└── migrations/
    ├── 00001_enable_pgvector.sql     # Extensions
    ├── 00002_create_sf_objects.sql   # Salesforce record metadata table
    ├── 00003_create_embeddings.sql   # Vector embeddings table
    ├── 00004_create_indexes.sql      # HNSW similarity search index
    └── 00005_create_functions.sql    # Similarity search RPC functions
```

## Applying Migrations

**Option A — Supabase CLI**
```bash
supabase link --project-ref <your-project-ref>
supabase db push
```

**Option B — Supabase SQL Editor**  
Paste and run each migration file in order (00001 → 00005) via the Supabase dashboard SQL editor.

## Tables

### `sf_objects`
Stores the Salesforce record metadata and the raw `source_text` that was sent to OpenAI for embedding. The `source_text` field is critical — it lets you reproduce any embedding and detect when normalization logic has changed.

### `sf_embeddings`
Stores the pgvector `vector(1536)` column alongside model metadata, a hash of the source text (for idempotency), and quality/review flags that your n8n QA workflows can populate.

## Key n8n Integration Points

Your n8n workflows should:
- **Upsert `sf_objects`** on `(sf_record_id, sf_object_type)` — safe to re-run on every sync
- **Upsert `sf_embeddings`** on `sf_object_id` — one embedding per record
- **Call `search_similar_records()`** via Supabase RPC for any similarity search node
- **Set `needs_review = TRUE`** on records your QA workflow flags

## Editing the Schema

Edit files in `supabase/migrations/`, commit, push to this repo, then apply via `supabase db push` or the SQL editor. Claude has full access to read and edit all files here.
