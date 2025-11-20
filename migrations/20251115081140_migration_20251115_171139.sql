-- Modify "workflow_bookmarks" table
ALTER TABLE "public"."workflow_bookmarks" ADD COLUMN IF NOT EXISTS "updated_at" timestamptz NULL DEFAULT now();
