-- Modify "tasks" table (module already added in 20251201100000 and renamed in 20251201100001)
-- Only add missing columns
ALTER TABLE "public"."tasks" ADD COLUMN IF NOT EXISTS "instructions" text NULL;
ALTER TABLE "public"."tasks" ADD COLUMN IF NOT EXISTS "is_standalone" boolean NOT NULL DEFAULT true;
