-- Create index "idx_chat_sessions_metadata_archived" to table: "chat_sessions"
CREATE INDEX "idx_chat_sessions_metadata_archived" ON "public"."chat_sessions" (((metadata ->> 'archived'::text)));
-- Create index "idx_chat_sessions_metadata_pinned" to table: "chat_sessions"
CREATE INDEX "idx_chat_sessions_metadata_pinned" ON "public"."chat_sessions" (((metadata ->> 'pinned'::text)));
-- Create index "idx_chat_sessions_user_archived_active" to table: "chat_sessions"
CREATE INDEX "idx_chat_sessions_user_archived_active" ON "public"."chat_sessions" ("user_id", ((metadata ->> 'archived'::text)), "last_active_at" DESC);
