-- Modify "environment_profiles" table
ALTER TABLE "public"."environment_profiles" ADD COLUMN "version" integer NULL DEFAULT 1, ADD COLUMN "build_size_mb" integer NULL, ADD COLUMN "requirements_txt" text NULL, ADD COLUMN "last_used_at" timestamptz NULL, ADD COLUMN "usage_count" integer NULL DEFAULT 0;
