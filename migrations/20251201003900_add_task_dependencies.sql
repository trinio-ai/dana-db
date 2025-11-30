-- Create task_dependencies table for navigation between related tasks
CREATE TABLE "public"."task_dependencies" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    -- Source task (the task user is currently on)
    "source_task_id" uuid NOT NULL,
    -- Target task (the task user navigates to)
    "target_task_id" uuid NOT NULL,
    -- Field in source task that triggers this navigation (optional, for UI hints)
    "source_field_name" character varying(255),
    -- Display label for the navigation link/button
    "label" character varying(100) NOT NULL DEFAULT 'Create New',
    -- Description shown to user
    "description" text,
    -- Metadata
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    CONSTRAINT "task_dependencies_source_task_id_fkey" FOREIGN KEY ("source_task_id") REFERENCES "public"."tasks" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
    CONSTRAINT "task_dependencies_target_task_id_fkey" FOREIGN KEY ("target_task_id") REFERENCES "public"."tasks" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
    -- Unique constraint on source, target, and field combination
    CONSTRAINT "task_dependencies_source_target_field_unique" UNIQUE ("source_task_id", "target_task_id", "source_field_name")
);

-- Create indexes for efficient querying
CREATE INDEX "idx_task_dependencies_source" ON "public"."task_dependencies" ("source_task_id");
CREATE INDEX "idx_task_dependencies_target" ON "public"."task_dependencies" ("target_task_id");

-- Add is_standalone column to tasks table
ALTER TABLE "public"."tasks" ADD COLUMN "is_standalone" boolean NOT NULL DEFAULT true;

-- Comment on columns for documentation
COMMENT ON TABLE "public"."task_dependencies" IS 'Directed edges between tasks allowing navigation when required data does not exist';
COMMENT ON COLUMN "public"."task_dependencies"."source_task_id" IS 'Task the user is currently working on';
COMMENT ON COLUMN "public"."task_dependencies"."target_task_id" IS 'Task the user can navigate to for creating required data';
COMMENT ON COLUMN "public"."task_dependencies"."source_field_name" IS 'Field name in source task that triggers navigation (e.g., customer, items[].item_code)';
COMMENT ON COLUMN "public"."task_dependencies"."label" IS 'Button/link label shown to user (e.g., + New Customer)';
COMMENT ON COLUMN "public"."tasks"."is_standalone" IS 'Whether this task can be executed independently without a multi-step workflow';
