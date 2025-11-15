-- Drop index "idx_chat_sessions_metadata_archived" from table: "chat_sessions"
DROP INDEX "public"."idx_chat_sessions_metadata_archived";
-- Drop index "idx_chat_sessions_metadata_pinned" from table: "chat_sessions"
DROP INDEX "public"."idx_chat_sessions_metadata_pinned";
-- Drop index "idx_chat_sessions_user_archived_active" from table: "chat_sessions"
DROP INDEX "public"."idx_chat_sessions_user_archived_active";
-- Modify "user_sessions" table
ALTER TABLE "public"."user_sessions" ADD COLUMN "last_activity" timestamptz NULL DEFAULT now(), ADD COLUMN "ip_address" character varying(45) NULL, ADD COLUMN "user_agent" text NULL;
-- Create index "idx_sessions_expires_at" to table: "user_sessions"
CREATE INDEX "idx_sessions_expires_at" ON "public"."user_sessions" ("expires_at");
-- Create index "idx_sessions_last_activity" to table: "user_sessions"
CREATE INDEX "idx_sessions_last_activity" ON "public"."user_sessions" ("last_activity");
