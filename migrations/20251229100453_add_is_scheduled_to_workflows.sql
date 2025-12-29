-- Add is_scheduled column to workflows table
ALTER TABLE "public"."workflows" ADD COLUMN "is_scheduled" boolean NOT NULL DEFAULT false;
-- Create index for is_scheduled column
CREATE INDEX "idx_workflows_is_scheduled" ON "public"."workflows" ("is_scheduled");
-- Make workflow_id NOT NULL in scheduled_workflows table
-- First, delete any scheduled_workflows with NULL workflow_id
DELETE FROM "public"."scheduled_workflows" WHERE "workflow_id" IS NULL;
-- Then, alter the column to NOT NULL
ALTER TABLE "public"."scheduled_workflows" ALTER COLUMN "workflow_id" SET NOT NULL;
-- Update existing scheduled workflows to mark their workflows as scheduled
UPDATE "public"."workflows" SET "is_scheduled" = true WHERE "id" IN (SELECT "workflow_id" FROM "public"."scheduled_workflows");
