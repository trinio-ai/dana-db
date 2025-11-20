-- Seed data for Python Dependency Registry
-- Standard libraries and environment profiles for task execution

-- ============================================================================
-- LIBRARY REGISTRY - Approved Python Libraries
-- ============================================================================

INSERT INTO library_registry (name, approved_versions, category, security_status, description, is_active)
VALUES
  -- Web & HTTP
  ('requests', ARRAY['2.31.0', '2.32.0'], 'web', 'safe', 'HTTP library for Python', true),
  ('httpx', ARRAY['0.27.0', '0.27.2'], 'web', 'safe', 'Async HTTP client', true),

  -- Data Processing
  ('pandas', ARRAY['2.0.0', '2.1.0', '2.2.0'], 'data', 'safe', 'Data analysis and manipulation', true),
  ('numpy', ARRAY['1.24.0', '1.25.0', '1.26.0'], 'data', 'safe', 'Numerical computing', true),

  -- Database
  ('psycopg2-binary', ARRAY['2.9.9'], 'database', 'safe', 'PostgreSQL adapter', true),
  ('sqlalchemy', ARRAY['2.0.0', '2.0.23'], 'database', 'safe', 'SQL toolkit and ORM', true),
  ('asyncpg', ARRAY['0.29.0'], 'database', 'safe', 'Async PostgreSQL driver', true),

  -- Utilities
  ('python-dateutil', ARRAY['2.8.2', '2.9.0'], 'utility', 'safe', 'Date and time utilities', true),
  ('pydantic', ARRAY['2.5.0', '2.6.0'], 'utility', 'safe', 'Data validation', true),

  -- Excel/Spreadsheet
  ('openpyxl', ARRAY['3.1.2'], 'data', 'safe', 'Excel file processing', true),
  ('xlrd', ARRAY['2.0.1'], 'data', 'safe', 'Read Excel files', true),

  -- JSON/YAML
  ('pyyaml', ARRAY['6.0.1'], 'utility', 'safe', 'YAML parser', true),

  -- Logging/Monitoring
  ('structlog', ARRAY['24.1.0'], 'utility', 'safe', 'Structured logging', true)
ON CONFLICT (name) DO UPDATE SET
  approved_versions = EXCLUDED.approved_versions,
  description = EXCLUDED.description,
  category = EXCLUDED.category,
  security_status = EXCLUDED.security_status,
  updated_at = NOW();

-- ============================================================================
-- ENVIRONMENT PROFILES - Pre-built Virtual Environments
-- ============================================================================

INSERT INTO environment_profiles (name, display_name, description, libraries, org_id, is_active)
VALUES
  -- Minimal profile for basic tasks
  (
    'erp-minimal',
    'ERP Minimal',
    'Minimal environment with essential utilities',
    '{
      "requests": "2.32.0",
      "python-dateutil": "2.9.0",
      "pydantic": "2.6.0"
    }'::jsonb,
    NULL,  -- Global profile
    true
  ),

  -- Standard profile with data processing
  (
    'erp-standard',
    'ERP Standard',
    'Standard environment with database and data processing libraries',
    '{
      "requests": "2.32.0",
      "pandas": "2.2.0",
      "numpy": "1.26.0",
      "psycopg2-binary": "2.9.9",
      "python-dateutil": "2.9.0",
      "pydantic": "2.6.0"
    }'::jsonb,
    NULL,  -- Global profile
    true
  ),

  -- Data analytics profile
  (
    'data-analytics',
    'Data Analytics',
    'Full data analytics stack with pandas, numpy, and visualization',
    '{
      "pandas": "2.2.0",
      "numpy": "1.26.0",
      "python-dateutil": "2.9.0",
      "openpyxl": "3.1.2"
    }'::jsonb,
    NULL,  -- Global profile
    true
  ),

  -- Database operations profile
  (
    'database-ops',
    'Database Operations',
    'Database-focused environment with SQLAlchemy and async drivers',
    '{
      "sqlalchemy": "2.0.23",
      "asyncpg": "0.29.0",
      "psycopg2-binary": "2.9.9",
      "pydantic": "2.6.0"
    }'::jsonb,
    NULL,  -- Global profile
    true
  ),

  -- Web API profile
  (
    'web-api',
    'Web API',
    'Environment for web API interactions',
    '{
      "requests": "2.32.0",
      "httpx": "0.27.2",
      "pydantic": "2.6.0",
      "pyyaml": "6.0.1"
    }'::jsonb,
    NULL,  -- Global profile
    true
  )
ON CONFLICT (name, org_id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  description = EXCLUDED.description,
  libraries = EXCLUDED.libraries,
  is_active = EXCLUDED.is_active,
  updated_at = NOW();

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Libraries seeded: 13 standard Python packages
-- Profiles seeded: 5 global environment profiles
-- All profiles are global (org_id = NULL), available to all organizations
-- Organizations can create custom profiles by setting org_id
