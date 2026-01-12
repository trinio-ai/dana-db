-- Create "workflow_tasks" table
CREATE TABLE "public"."workflow_tasks" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "workflow_id" uuid NOT NULL,
  "task_id" uuid NOT NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "workflow_tasks_workflow_id_task_id_key" UNIQUE ("workflow_id", "task_id"),
  CONSTRAINT "workflow_tasks_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "workflow_tasks_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "public"."workflows" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_workflow_tasks_task" to table: "workflow_tasks"
CREATE INDEX "idx_workflow_tasks_task" ON "public"."workflow_tasks" ("task_id");
-- Create index "idx_workflow_tasks_workflow" to table: "workflow_tasks"
CREATE INDEX "idx_workflow_tasks_workflow" ON "public"."workflow_tasks" ("workflow_id");
