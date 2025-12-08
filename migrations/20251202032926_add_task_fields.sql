-- Modify "tasks" table
ALTER TABLE "public"."tasks" ADD COLUMN "module" character varying(50) NULL, ADD COLUMN "instructions" text NULL, ADD COLUMN "is_standalone" boolean NOT NULL DEFAULT true;
-- Create index "idx_tasks_module" to table: "tasks"
CREATE INDEX "idx_tasks_module" ON "public"."tasks" ("module");
