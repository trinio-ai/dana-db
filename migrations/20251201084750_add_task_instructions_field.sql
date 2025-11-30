-- Add instructions and is_standalone columns to tasks table
-- instructions: Text field for task-specific instructions/guidance
-- is_standalone: Boolean indicating if task can be executed independently

ALTER TABLE tasks ADD COLUMN IF NOT EXISTS instructions TEXT;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS is_standalone BOOLEAN NOT NULL DEFAULT true;
