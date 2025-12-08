-- Modify "organizations" table
ALTER TABLE "public"."organizations" DROP COLUMN "is_sandbox", DROP COLUMN "source_organization_id";
-- Create "task_modules" table
CREATE TABLE "public"."task_modules" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "slug" character varying(50) NOT NULL,
  "name" character varying(100) NOT NULL,
  "description" text NULL,
  "icon" character varying(50) NULL,
  "display_order" integer NULL DEFAULT 0,
  "is_active" boolean NULL DEFAULT true,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "task_modules_organization_id_slug_key" UNIQUE ("organization_id", "slug"),
  CONSTRAINT "task_modules_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_task_modules_org" to table: "task_modules"
CREATE INDEX "idx_task_modules_org" ON "public"."task_modules" ("organization_id");
-- Create index "idx_task_modules_slug" to table: "task_modules"
CREATE INDEX "idx_task_modules_slug" ON "public"."task_modules" ("slug");
