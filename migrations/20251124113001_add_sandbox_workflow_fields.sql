-- Migration: Add Sandbox Workflow fields
-- Description: Add is_sandbox and source_workflow_id fields to workflows table for sandbox environment management
-- Date: 2024-11-20

-- Add is_sandbox column to workflows table
ALTER TABLE workflows
ADD COLUMN IF NOT EXISTS is_sandbox BOOLEAN DEFAULT FALSE NOT NULL;

-- Add index on is_sandbox for better query performance
CREATE INDEX IF NOT EXISTS idx_workflows_is_sandbox
ON workflows(is_sandbox);

-- Add source_workflow_id column to workflows table
ALTER TABLE workflows
ADD COLUMN IF NOT EXISTS source_workflow_id UUID;

-- Add foreign key constraint with CASCADE delete
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_workflows_source_workflow'
        AND table_name = 'workflows'
    ) THEN
        ALTER TABLE workflows
        ADD CONSTRAINT fk_workflows_source_workflow
        FOREIGN KEY (source_workflow_id)
        REFERENCES workflows(id)
        ON DELETE CASCADE;
    END IF;
END $$;

-- Add index on source_workflow_id for better join performance
CREATE INDEX IF NOT EXISTS idx_workflows_source_workflow_id
ON workflows(source_workflow_id);

-- Verify changes
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'workflows'
    AND column_name IN ('is_sandbox', 'source_workflow_id')
ORDER BY ordinal_position;

-- Verify foreign key constraint
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
    ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'workflows'
    AND kcu.column_name = 'source_workflow_id';
