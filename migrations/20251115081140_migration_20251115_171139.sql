-- Modify "workflow_bookmarks" table
ALTER TABLE "public"."workflow_bookmarks" ADD COLUMN "updated_at" timestamptz NULL DEFAULT now();
