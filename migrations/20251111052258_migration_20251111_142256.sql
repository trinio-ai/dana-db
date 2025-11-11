-- Create "langchain_pg_collection" table (if not exists)
-- Note: LangChain may auto-create this table on first use
CREATE TABLE IF NOT EXISTS "public"."langchain_pg_collection" (
  "name" character varying NULL,
  "cmetadata" json NULL,
  "uuid" uuid NOT NULL,
  PRIMARY KEY ("uuid")
);

-- Create "langchain_pg_embedding" table (if not exists)
-- Note: LangChain may auto-create this table on first use
CREATE TABLE IF NOT EXISTS "public"."langchain_pg_embedding" (
  "collection_id" uuid NULL,
  "embedding" public.vector NULL,
  "document" character varying NULL,
  "cmetadata" jsonb NULL,
  "custom_id" character varying NULL,
  "uuid" uuid NOT NULL,
  PRIMARY KEY ("uuid"),
  CONSTRAINT "langchain_pg_embedding_collection_id_fkey" FOREIGN KEY ("collection_id") REFERENCES "public"."langchain_pg_collection" ("uuid") ON UPDATE NO ACTION ON DELETE CASCADE
);

-- Create index "ix_cmetadata_gin" to table: "langchain_pg_embedding" (if not exists)
-- This index is critical for fast JSONB metadata filtering (organization_id, workflow_id, etc.)
CREATE INDEX IF NOT EXISTS "ix_cmetadata_gin" ON "public"."langchain_pg_embedding" USING gin ("cmetadata" jsonb_path_ops);
