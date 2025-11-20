-- Add updated_at column to conversation_turns table
ALTER TABLE "public"."conversation_turns" ADD COLUMN IF NOT EXISTS "updated_at" timestamptz NOT NULL DEFAULT now();
