-- Create "library_registry" table
CREATE TABLE "public"."library_registry" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "name" character varying(255) NOT NULL,
  "approved_versions" text[] NOT NULL DEFAULT '{}',
  "description" text NULL,
  "category" character varying(100) NULL,
  "security_status" character varying(50) NULL DEFAULT 'safe',
  "is_active" boolean NULL DEFAULT true,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "library_registry_name_key" UNIQUE ("name")
);
-- Create index "idx_library_registry_active" to table: "library_registry"
CREATE INDEX "idx_library_registry_active" ON "public"."library_registry" ("is_active");
-- Create index "idx_library_registry_category" to table: "library_registry"
CREATE INDEX "idx_library_registry_category" ON "public"."library_registry" ("category");
-- Create index "idx_library_registry_name" to table: "library_registry"
CREATE INDEX "idx_library_registry_name" ON "public"."library_registry" ("name");
-- Create "environment_profiles" table
CREATE TABLE "public"."environment_profiles" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "name" character varying(255) NOT NULL,
  "display_name" character varying(255) NOT NULL,
  "description" text NULL,
  "libraries" jsonb NOT NULL DEFAULT '{}',
  "is_built" boolean NULL DEFAULT false,
  "build_path" character varying(500) NULL,
  "build_date" timestamptz NULL,
  "org_id" uuid NULL,
  "is_active" boolean NULL DEFAULT true,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "environment_profiles_name_org_id_key" UNIQUE ("name", "org_id"),
  CONSTRAINT "environment_profiles_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_environment_profiles_active" to table: "environment_profiles"
CREATE INDEX "idx_environment_profiles_active" ON "public"."environment_profiles" ("is_active");
-- Create index "idx_environment_profiles_name" to table: "environment_profiles"
CREATE INDEX "idx_environment_profiles_name" ON "public"."environment_profiles" ("name");
-- Create index "idx_environment_profiles_org" to table: "environment_profiles"
CREATE INDEX "idx_environment_profiles_org" ON "public"."environment_profiles" ("org_id");
-- Modify "tasks" table
ALTER TABLE "public"."tasks" ADD COLUMN "environment_profile_id" uuid NULL, ADD CONSTRAINT "fk_task_env_profile" FOREIGN KEY ("environment_profile_id") REFERENCES "public"."environment_profiles" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;
-- Create index "idx_tasks_env_profile" to table: "tasks"
CREATE INDEX "idx_tasks_env_profile" ON "public"."tasks" ("environment_profile_id");
-- Create "task_library_requirements" table
CREATE TABLE "public"."task_library_requirements" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "task_id" uuid NOT NULL,
  "library_name" character varying(255) NOT NULL,
  "library_version" character varying(50) NOT NULL,
  "is_required" boolean NULL DEFAULT true,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "task_library_requirements_task_id_library_name_key" UNIQUE ("task_id", "library_name"),
  CONSTRAINT "task_library_requirements_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_task_library_req_library" to table: "task_library_requirements"
CREATE INDEX "idx_task_library_req_library" ON "public"."task_library_requirements" ("library_name");
-- Create index "idx_task_library_req_task" to table: "task_library_requirements"
CREATE INDEX "idx_task_library_req_task" ON "public"."task_library_requirements" ("task_id");
