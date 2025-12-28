-- Modify "task_executions" table
ALTER TABLE "public"."task_executions" ADD CONSTRAINT "chk_execution_type" CHECK (((workflow_execution_id IS NOT NULL) AND (scheduled_workflow_execution_id IS NULL)) OR ((workflow_execution_id IS NULL) AND (scheduled_workflow_execution_id IS NOT NULL)) OR ((workflow_execution_id IS NULL) AND (scheduled_workflow_execution_id IS NULL))), ADD COLUMN "scheduled_workflow_execution_id" uuid NULL;
-- Create index "idx_task_executions_scheduled_workflow" to table: "task_executions"
CREATE INDEX "idx_task_executions_scheduled_workflow" ON "public"."task_executions" ("scheduled_workflow_execution_id");
-- Rename a constraint from "scheduled_tasks_pkey" to "scheduled_workflows_pkey"
ALTER TABLE "public"."scheduled_workflows" RENAME CONSTRAINT "scheduled_tasks_pkey" TO "scheduled_workflows_pkey";
-- Modify "scheduled_workflows" table
ALTER TABLE "public"."scheduled_workflows" DROP CONSTRAINT "scheduled_tasks_agent_id_fkey", DROP CONSTRAINT "scheduled_tasks_created_by_fkey", DROP CONSTRAINT "scheduled_tasks_organization_id_fkey", DROP CONSTRAINT "scheduled_tasks_workflow_id_fkey", ADD CONSTRAINT "scheduled_workflows_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."ai_agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION, ADD CONSTRAINT "scheduled_workflows_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION, ADD CONSTRAINT "scheduled_workflows_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION, ADD CONSTRAINT "scheduled_workflows_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "public"."workflows" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- Create "scheduled_workflow_executions" table
CREATE TABLE "public"."scheduled_workflow_executions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "scheduled_workflow_id" uuid NOT NULL,
  "workflow_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "org_id" uuid NOT NULL,
  "status" character varying(20) NULL DEFAULT 'pending',
  "input_parameters" jsonb NULL,
  "result_data" jsonb NULL,
  "execution_graph" jsonb NULL,
  "current_tasks" jsonb NULL DEFAULT '[]',
  "error_message" text NULL,
  "error_details" jsonb NULL,
  "retry_count" integer NULL DEFAULT 0,
  "max_retries" integer NULL DEFAULT 3,
  "execution_time_ms" integer NULL,
  "queue_time_ms" integer NULL,
  "total_tasks" integer NULL DEFAULT 0,
  "completed_tasks" integer NULL DEFAULT 0,
  "worker_id" character varying(255) NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "started_at" timestamptz NULL,
  "completed_at" timestamptz NULL,
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "scheduled_workflow_executions_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "scheduled_workflow_executions_scheduled_workflow_id_fkey" FOREIGN KEY ("scheduled_workflow_id") REFERENCES "public"."scheduled_workflows" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "scheduled_workflow_executions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "scheduled_workflow_executions_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "public"."workflows" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_scheduled_workflow_executions_org" to table: "scheduled_workflow_executions"
CREATE INDEX "idx_scheduled_workflow_executions_org" ON "public"."scheduled_workflow_executions" ("org_id");
-- Create index "idx_scheduled_workflow_executions_scheduled" to table: "scheduled_workflow_executions"
CREATE INDEX "idx_scheduled_workflow_executions_scheduled" ON "public"."scheduled_workflow_executions" ("scheduled_workflow_id", "created_at" DESC);
-- Create index "idx_scheduled_workflow_executions_status" to table: "scheduled_workflow_executions"
CREATE INDEX "idx_scheduled_workflow_executions_status" ON "public"."scheduled_workflow_executions" ("status");
-- Create index "idx_scheduled_workflow_executions_workflow" to table: "scheduled_workflow_executions"
CREATE INDEX "idx_scheduled_workflow_executions_workflow" ON "public"."scheduled_workflow_executions" ("workflow_id");
