-- Modify "chat_sessions" table
ALTER TABLE "public"."chat_sessions" ADD COLUMN "updated_at" timestamptz NULL DEFAULT now();
-- Modify "conversation_turns" table
ALTER TABLE "public"."conversation_turns" ADD COLUMN "updated_at" timestamptz NULL DEFAULT now();
