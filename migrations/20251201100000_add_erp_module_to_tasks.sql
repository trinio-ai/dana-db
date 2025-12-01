-- Add erp_module column to tasks table
-- ERP modules: master-data, selling, buying, inventory, manufacturing, accounting

ALTER TABLE tasks ADD COLUMN erp_module VARCHAR(50) NULL;

-- Create index for filtering
CREATE INDEX idx_tasks_erp_module ON tasks(erp_module);
