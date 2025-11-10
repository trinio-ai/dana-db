-- Modify "tasks" table
-- Add new endpoint fields for core tasks
ALTER TABLE "public"."tasks"
    ADD COLUMN "fetch_endpoint" character varying(500) NULL,
    ADD COLUMN "commit_endpoint" character varying(500) NULL;

-- Remove deprecated erp_core_endpoint column
ALTER TABLE "public"."tasks" DROP COLUMN IF EXISTS "erp_core_endpoint";

-- Modify "task_executions" table
-- Copy existing erp_core_instance data to new executor_instance column
ALTER TABLE "public"."task_executions" ADD COLUMN "executor_instance" character varying(255) NULL;
UPDATE "public"."task_executions" SET "executor_instance" = "erp_core_instance" WHERE "erp_core_instance" IS NOT NULL;

-- Drop deprecated erp_core_instance column
ALTER TABLE "public"."task_executions" DROP COLUMN IF EXISTS "erp_core_instance";
