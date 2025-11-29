-- Modify "tasks" table
ALTER TABLE "public"."tasks" DROP CONSTRAINT "fk_tasks_source_task", ALTER COLUMN "is_sandbox" DROP NOT NULL, ADD CONSTRAINT "tasks_source_task_id_fkey" FOREIGN KEY ("source_task_id") REFERENCES "public"."tasks" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- Modify "workflow_executions" table
ALTER TABLE "public"."workflow_executions" ADD COLUMN "display_name" character varying(255) NULL;
-- Modify "workflows" table
ALTER TABLE "public"."workflows" DROP CONSTRAINT "fk_workflows_source_workflow", ALTER COLUMN "is_sandbox" DROP NOT NULL, ADD CONSTRAINT "workflows_source_workflow_id_fkey" FOREIGN KEY ("source_workflow_id") REFERENCES "public"."workflows" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
