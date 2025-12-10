-- Modify "organizations" table
ALTER TABLE "public"."organizations" ADD COLUMN "is_sandbox" boolean NOT NULL DEFAULT false, ADD COLUMN "source_organization_id" uuid NULL, ADD
CONSTRAINT "organizations_source_organization_id_fkey" FOREIGN KEY ("source_organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- Create index "idx_organizations_is_sandbox" to table: "organizations"
CREATE INDEX "idx_organizations_is_sandbox" ON "public"."organizations" ("is_sandbox");
-- Create index "idx_organizations_source_organization_id" to table: "organizations"
CREATE INDEX "idx_organizations_source_organization_id" ON "public"."organizations" ("source_organization_id");
-- Modify "tasks" table
ALTER TABLE "public"."tasks" DROP CONSTRAINT "fk_tasks_source_task", ALTER COLUMN "is_sandbox" DROP NOT NULL, ADD
CONSTRAINT "tasks_source_task_id_fkey" FOREIGN KEY ("source_task_id") REFERENCES "public"."tasks" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
-- Modify "workflows" table
ALTER TABLE "public"."workflows" DROP CONSTRAINT "fk_workflows_source_workflow", ALTER COLUMN "is_sandbox" DROP NOT NULL, ADD
CONSTRAINT "workflows_source_workflow_id_fkey" FOREIGN KEY ("source_workflow_id") REFERENCES "public"."workflows" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
