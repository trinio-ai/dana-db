-- Migration: Add Sandbox Task fields
-- Description: Add is_sandbox and source_task_id fields to tasks table for sandbox environment management
-- Date: 2024-11-20

-- Add is_sandbox column to tasks table
ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS is_sandbox BOOLEAN DEFAULT FALSE NOT NULL;

-- Add index on is_sandbox for better query performance
CREATE INDEX IF NOT EXISTS idx_tasks_is_sandbox
ON tasks(is_sandbox);

-- Add source_task_id column to tasks table
ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS source_task_id UUID;

-- Add foreign key constraint with CASCADE delete
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_tasks_source_task'
        AND table_name = 'tasks'
    ) THEN
        ALTER TABLE tasks
        ADD CONSTRAINT fk_tasks_source_task
        FOREIGN KEY (source_task_id)
        REFERENCES tasks(id)
        ON DELETE CASCADE;
    END IF;
END $$;

-- Add index on source_task_id for better join performance
CREATE INDEX IF NOT EXISTS idx_tasks_source_task_id
ON tasks(source_task_id);

-- Verify changes
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'tasks'
    AND column_name IN ('is_sandbox', 'source_task_id')
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
    AND tc.table_name = 'tasks'
    AND kcu.column_name = 'source_task_id';
