-- Create "modules" table
CREATE TABLE "public"."modules" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "name" character varying(255) NOT NULL,
  "description" text NULL,
  "parent_module_id" uuid NULL,
  "path" text NOT NULL,
  "module_type" character varying(20) NULL DEFAULT 'folder',
  "created_by" uuid NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "unique_org_path" UNIQUE ("organization_id", "path"),
  CONSTRAINT "modules_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "modules_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "modules_parent_module_id_fkey" FOREIGN KEY ("parent_module_id") REFERENCES "public"."modules" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_modules_org" to table: "modules"
CREATE INDEX "idx_modules_org" ON "public"."modules" ("organization_id");
-- Create index "idx_modules_parent" to table: "modules"
CREATE INDEX "idx_modules_parent" ON "public"."modules" ("parent_module_id");
-- Create index "idx_modules_path" to table: "modules"
CREATE INDEX "idx_modules_path" ON "public"."modules" ("organization_id", "path");
-- Modify "workflows" table
ALTER TABLE "public"."workflows" DROP COLUMN "workflow_category", ADD COLUMN "module_id" uuid NULL, ADD CONSTRAINT "workflows_module_id_fkey" FOREIGN KEY ("module_id") REFERENCES "public"."modules" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- Create index "idx_workflows_module" to table: "workflows"
CREATE INDEX "idx_workflows_module" ON "public"."workflows" ("module_id");
