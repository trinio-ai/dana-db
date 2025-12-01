-- Create "task_modules" table
CREATE TABLE "public"."task_modules" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "slug" character varying(50) NOT NULL,
  "name" character varying(100) NOT NULL,
  "description" text NULL,
  "icon" character varying(50) NULL,
  "display_order" integer NOT NULL DEFAULT 0,
  "is_active" boolean NOT NULL DEFAULT true,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "unique_org_module_slug" UNIQUE ("organization_id", "slug"),
  CONSTRAINT "task_modules_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX "idx_task_modules_org" ON "public"."task_modules" ("organization_id");
CREATE INDEX "idx_task_modules_slug" ON "public"."task_modules" ("slug");
CREATE INDEX "idx_task_modules_active" ON "public"."task_modules" ("organization_id", "is_active");
