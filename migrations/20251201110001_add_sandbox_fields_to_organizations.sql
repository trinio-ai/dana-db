-- Modify "organizations" table (idempotent)
DO $$
BEGIN
    -- Add is_sandbox column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'organizations' AND column_name = 'is_sandbox') THEN
        ALTER TABLE "public"."organizations" ADD COLUMN "is_sandbox" boolean NOT NULL DEFAULT false;
    END IF;

    -- Add source_organization_id column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'organizations' AND column_name = 'source_organization_id') THEN
        ALTER TABLE "public"."organizations" ADD COLUMN "source_organization_id" uuid NULL;
    END IF;

    -- Add foreign key constraint if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'organizations_source_organization_id_fkey' AND table_schema = 'public') THEN
        ALTER TABLE "public"."organizations" ADD CONSTRAINT "organizations_source_organization_id_fkey" FOREIGN KEY ("source_organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;
    END IF;
END $$;

-- Create index "idx_org_is_sandbox" to table: "organizations" (idempotent)
CREATE INDEX IF NOT EXISTS "idx_org_is_sandbox" ON "public"."organizations" ("is_sandbox");
-- Create index "idx_org_source_organization_id" to table: "organizations" (idempotent)
CREATE INDEX IF NOT EXISTS "idx_org_source_organization_id" ON "public"."organizations" ("source_organization_id");
-- Set comment to table: "task_dependencies"
COMMENT ON TABLE "public"."task_dependencies" IS NULL;
-- Set comment to column: "source_task_id" on table: "task_dependencies"
COMMENT ON COLUMN "public"."task_dependencies"."source_task_id" IS NULL;
-- Set comment to column: "target_task_id" on table: "task_dependencies"
COMMENT ON COLUMN "public"."task_dependencies"."target_task_id" IS NULL;
-- Set comment to column: "source_field_name" on table: "task_dependencies"
COMMENT ON COLUMN "public"."task_dependencies"."source_field_name" IS NULL;
-- Set comment to column: "label" on table: "task_dependencies"
COMMENT ON COLUMN "public"."task_dependencies"."label" IS NULL;
-- Set comment to column: "is_standalone" on table: "tasks"
COMMENT ON COLUMN "public"."tasks"."is_standalone" IS NULL;
