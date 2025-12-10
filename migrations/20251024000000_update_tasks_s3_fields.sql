-- Migration: Update tasks table to support multiple S3 resources
-- Description: Replace single S3 object fields with individual S3 key, version, and hash fields
--              for each task resource (html_component, validation_schema,
--              data_fetch_code, data_commit_code)

-- Drop the old check constraint
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS check_storage_consistency;

-- Remove old text/jsonb columns that will be stored in S3
ALTER TABLE tasks DROP COLUMN IF EXISTS html_component;
ALTER TABLE tasks DROP COLUMN IF EXISTS validation_schema;
ALTER TABLE tasks DROP COLUMN IF EXISTS data_fetch_code;
ALTER TABLE tasks DROP COLUMN IF EXISTS data_commit_code;

-- Remove old single-object S3 fields
ALTER TABLE tasks DROP COLUMN IF EXISTS s3_key;
ALTER TABLE tasks DROP COLUMN IF EXISTS s3_version_id;
ALTER TABLE tasks DROP COLUMN IF EXISTS code_hash;

-- Keep s3_bucket but make it NOT NULL (all tasks will use S3 storage)
-- Note: s3_bucket should already exist, we're just updating the constraint
ALTER TABLE tasks ALTER COLUMN s3_bucket SET NOT NULL;

-- Add S3 key columns for each resource
-- html_component is required for all tasks
ALTER TABLE tasks ADD COLUMN html_component_s3_key VARCHAR(500) NOT NULL DEFAULT '';
ALTER TABLE tasks ADD COLUMN html_component_version_id VARCHAR(255);
ALTER TABLE tasks ADD COLUMN html_component_hash VARCHAR(64);

-- validation_schema is required for all tasks
ALTER TABLE tasks ADD COLUMN validation_schema_s3_key VARCHAR(500) NOT NULL DEFAULT '';
ALTER TABLE tasks ADD COLUMN validation_schema_version_id VARCHAR(255);
ALTER TABLE tasks ADD COLUMN validation_schema_hash VARCHAR(64);

-- data_fetch_code is optional (only for tasks with data fetch operations)
ALTER TABLE tasks ADD COLUMN data_fetch_code_s3_key VARCHAR(500);
ALTER TABLE tasks ADD COLUMN data_fetch_code_version_id VARCHAR(255);
ALTER TABLE tasks ADD COLUMN data_fetch_code_hash VARCHAR(64);

-- data_commit_code is optional (only for tasks with data commit operations)
ALTER TABLE tasks ADD COLUMN data_commit_code_s3_key VARCHAR(500);
ALTER TABLE tasks ADD COLUMN data_commit_code_version_id VARCHAR(255);
ALTER TABLE tasks ADD COLUMN data_commit_code_hash VARCHAR(64);

-- Remove the default constraint after adding columns (we only needed it for migration)
ALTER TABLE tasks ALTER COLUMN html_component_s3_key DROP DEFAULT;
ALTER TABLE tasks ALTER COLUMN validation_schema_s3_key DROP DEFAULT;

-- Add new check constraint to ensure S3 bucket is set for all tasks
ALTER TABLE tasks ADD CONSTRAINT check_s3_storage CHECK (s3_bucket IS NOT NULL);
