-- Modify "organizations" table (remove sandbox columns added earlier)
ALTER TABLE "public"."organizations" DROP COLUMN IF EXISTS "is_sandbox", DROP COLUMN IF EXISTS "source_organization_id";
-- Note: task_modules table already created in 20251201110000_add_task_modules_table.sql
