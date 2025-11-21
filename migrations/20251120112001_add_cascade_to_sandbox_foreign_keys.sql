-- Migration: Add CASCADE to sandbox foreign key constraints
-- Description: Ensure sandbox tasks/workflows are automatically deleted when source task/workflow is deleted
-- Date: 2024-11-18
-- Note: Only applies constraints if columns exist

-- Tasks table: Drop and recreate source_task_id constraint with CASCADE (if column exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'tasks' AND column_name = 'source_task_id'
    ) THEN
        ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_source_task_id_fkey;
        ALTER TABLE tasks
        ADD CONSTRAINT tasks_source_task_id_fkey
        FOREIGN KEY (source_task_id)
        REFERENCES tasks(id)
        ON DELETE CASCADE;
    END IF;
END $$;

-- Workflows table: Drop and recreate source_workflow_id constraint with CASCADE (if column exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'workflows' AND column_name = 'source_workflow_id'
    ) THEN
        ALTER TABLE workflows DROP CONSTRAINT IF EXISTS workflows_source_workflow_id_fkey;
        ALTER TABLE workflows
        ADD CONSTRAINT workflows_source_workflow_id_fkey
        FOREIGN KEY (source_workflow_id)
        REFERENCES workflows(id)
        ON DELETE CASCADE;
    END IF;
END $$;

-- Verify constraints
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
    AND (
        (tc.table_name = 'tasks' AND kcu.column_name = 'source_task_id')
        OR (tc.table_name = 'workflows' AND kcu.column_name = 'source_workflow_id')
    );
