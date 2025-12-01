-- Rename erp_module column to module (tasks can be part of any system, not just ERP)

ALTER TABLE tasks RENAME COLUMN erp_module TO module;

-- Rename index
DROP INDEX IF EXISTS idx_tasks_erp_module;
CREATE INDEX idx_tasks_module ON tasks(module);
