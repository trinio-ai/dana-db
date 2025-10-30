-- Create "chat_document_embeddings" table
CREATE TABLE "public"."chat_document_embeddings" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "collection_name" character varying(50) NOT NULL,
  "document_id" character varying(255) NOT NULL,
  "content" text NOT NULL,
  "embedding" public.vector(384) NOT NULL,
  "metadata" jsonb NOT NULL DEFAULT '{}',
  "content_tsv" tsvector NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "chat_document_embeddings_unique" UNIQUE ("collection_name", "document_id"),
  CONSTRAINT "chat_document_embeddings_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_chat_doc_embeddings_collection" to table: "chat_document_embeddings"
CREATE INDEX "idx_chat_doc_embeddings_collection" ON "public"."chat_document_embeddings" ("collection_name");
-- Create index "idx_chat_doc_embeddings_fts" to table: "chat_document_embeddings"
CREATE INDEX "idx_chat_doc_embeddings_fts" ON "public"."chat_document_embeddings" USING gin ("content_tsv");
-- Create index "idx_chat_doc_embeddings_org" to table: "chat_document_embeddings"
CREATE INDEX "idx_chat_doc_embeddings_org" ON "public"."chat_document_embeddings" ("organization_id");
-- Create index "idx_chat_doc_embeddings_vector" to table: "chat_document_embeddings"
CREATE INDEX "idx_chat_doc_embeddings_vector" ON "public"."chat_document_embeddings" USING hnsw ("embedding" vector_cosine_ops);
-- Create "chat_sessions" table
CREATE TABLE "public"."chat_sessions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_id" uuid NOT NULL,
  "organization_id" uuid NOT NULL,
  "user_role" character varying(20) NOT NULL,
  "metadata" jsonb NOT NULL DEFAULT '{}',
  "created_at" timestamptz NULL DEFAULT now(),
  "last_active_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "chat_sessions_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "chat_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_chat_sessions_last_active" to table: "chat_sessions"
CREATE INDEX "idx_chat_sessions_last_active" ON "public"."chat_sessions" ("last_active_at");
-- Create index "idx_chat_sessions_org" to table: "chat_sessions"
CREATE INDEX "idx_chat_sessions_org" ON "public"."chat_sessions" ("organization_id");
-- Create index "idx_chat_sessions_user" to table: "chat_sessions"
CREATE INDEX "idx_chat_sessions_user" ON "public"."chat_sessions" ("user_id");
-- Create "conversation_turns" table
CREATE TABLE "public"."conversation_turns" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "session_id" uuid NOT NULL,
  "user_message" text NOT NULL,
  "assistant_message" text NOT NULL,
  "intent" character varying(50) NOT NULL,
  "agent_type" character varying(50) NOT NULL,
  "confidence" double precision NOT NULL,
  "latency_ms" double precision NOT NULL,
  "metadata" jsonb NOT NULL DEFAULT '{}',
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "conversation_turns_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."chat_sessions" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_conversation_turns_agent" to table: "conversation_turns"
CREATE INDEX "idx_conversation_turns_agent" ON "public"."conversation_turns" ("agent_type");
-- Create index "idx_conversation_turns_created" to table: "conversation_turns"
CREATE INDEX "idx_conversation_turns_created" ON "public"."conversation_turns" ("created_at");
-- Create index "idx_conversation_turns_intent" to table: "conversation_turns"
CREATE INDEX "idx_conversation_turns_intent" ON "public"."conversation_turns" ("intent");
-- Create index "idx_conversation_turns_session" to table: "conversation_turns"
CREATE INDEX "idx_conversation_turns_session" ON "public"."conversation_turns" ("session_id");
