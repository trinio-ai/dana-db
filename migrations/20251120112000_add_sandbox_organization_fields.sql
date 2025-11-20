-- Migration: Add Sandbox Organization fields
-- Description: Add is_sandbox and source_organization_id fields to organizations table for sandbox environment management
-- Date: 2024-11-18

-- Add is_sandbox column to organizations table
ALTER TABLE organizations
ADD COLUMN IF NOT EXISTS is_sandbox BOOLEAN DEFAULT FALSE NOT NULL;

-- Add index on is_sandbox for better query performance
CREATE INDEX IF NOT EXISTS idx_organizations_is_sandbox
ON organizations(is_sandbox);

-- Add source_organization_id column to organizations table
ALTER TABLE organizations
ADD COLUMN IF NOT EXISTS source_organization_id UUID;

-- Add foreign key constraint with CASCADE delete
ALTER TABLE organizations
ADD CONSTRAINT fk_organizations_source_organization
FOREIGN KEY (source_organization_id)
REFERENCES organizations(id)
ON DELETE CASCADE;

-- Add index on source_organization_id for better join performance
CREATE INDEX IF NOT EXISTS idx_organizations_source_organization_id
ON organizations(source_organization_id);

-- Verify changes
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'organizations'
    AND column_name IN ('is_sandbox', 'source_organization_id')
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
    AND tc.table_name = 'organizations'
    AND kcu.column_name = 'source_organization_id';
