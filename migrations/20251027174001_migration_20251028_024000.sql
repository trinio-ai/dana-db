-- Modify "workflow_permissions" table
ALTER TABLE "public"."workflow_permissions" ADD COLUMN "updated_at" timestamptz NULL DEFAULT now();
