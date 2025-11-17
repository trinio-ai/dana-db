-- Add updated_at column to chat_sessions table
ALTER TABLE "public"."chat_sessions" ADD COLUMN "updated_at" timestamptz NOT NULL DEFAULT now();
