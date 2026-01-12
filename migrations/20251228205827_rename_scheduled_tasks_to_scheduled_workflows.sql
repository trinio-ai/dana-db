-- Set comment to table: "task_dependencies"
COMMENT ON TABLE "public"."task_dependencies" IS NULL;
-- Set comment to column: "source_task_id" on table: "task_dependencies"
COMMENT ON COLUMN "public"."task_dependencies"."source_task_id" IS NULL;
-- Set comment to column: "target_task_id" on table: "task_dependencies"
COMMENT ON COLUMN "public"."task_dependencies"."target_task_id" IS NULL;
-- Set comment to column: "source_field_name" on table: "task_dependencies"
COMMENT ON COLUMN "public"."task_dependencies"."source_field_name" IS NULL;
-- Set comment to column: "label" on table: "task_dependencies"
COMMENT ON COLUMN "public"."task_dependencies"."label" IS NULL;
-- Set comment to column: "is_standalone" on table: "tasks"
COMMENT ON COLUMN "public"."tasks"."is_standalone" IS NULL;
-- Rename "scheduled_tasks" table to "scheduled_workflows"
ALTER TABLE "public"."scheduled_tasks" RENAME TO "scheduled_workflows";
-- Rename indexes
ALTER INDEX "idx_scheduled_tasks_org" RENAME TO "idx_scheduled_workflows_org";
ALTER INDEX "idx_scheduled_tasks_status" RENAME TO "idx_scheduled_workflows_status";
ALTER INDEX "idx_scheduled_tasks_next_run" RENAME TO "idx_scheduled_workflows_next_run";
