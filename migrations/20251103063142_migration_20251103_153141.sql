-- Modify "task_executions" table
ALTER TABLE "public"."task_executions" ADD COLUMN "task_index" integer NULL DEFAULT 0, ADD COLUMN "max_retries" integer NULL DEFAULT 0, ADD COLUMN "started_at" timestamptz NULL, ADD COLUMN "completed_at" timestamptz NULL;
-- Modify "workflow_executions" table
ALTER TABLE "public"."workflow_executions" ADD COLUMN "org_id" uuid NOT NULL, ADD COLUMN "total_tasks" integer NULL DEFAULT 0, ADD COLUMN "completed_tasks" integer NULL DEFAULT 0, ADD COLUMN "started_at" timestamptz NULL, ADD COLUMN "completed_at" timestamptz NULL, ADD CONSTRAINT "workflow_executions_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- Create index "idx_workflow_executions_org" to table: "workflow_executions"
CREATE INDEX "idx_workflow_executions_org" ON "public"."workflow_executions" ("org_id");
