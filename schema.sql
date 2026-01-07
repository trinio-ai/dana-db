-- DANA OS Database Schema
-- Based on DANA_PRD.md v3.0
-- Complete schema for enterprise data operations system

-- NOTE: Extensions are installed via migration 20251023000000_initial_extensions.sql
-- This file contains only the table definitions

-- ============================================================================
-- ORGANIZATIONS & USERS
-- ============================================================================

-- Organizations (Multi-tenant root table)
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    plan_type VARCHAR(50) NOT NULL DEFAULT 'starter',
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    settings JSONB DEFAULT '{}',
    is_sandbox BOOLEAN NOT NULL DEFAULT false,
    source_organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_org_slug ON organizations(slug);
CREATE INDEX idx_org_status ON organizations(status);
CREATE INDEX idx_org_is_sandbox ON organizations(is_sandbox);
CREATE INDEX idx_org_source_organization_id ON organizations(source_organization_id);

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'member',
    is_active BOOLEAN NOT NULL DEFAULT true,
    permissions JSONB DEFAULT '{}',
    preferences JSONB DEFAULT '{}',
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_org ON users(organization_id);
CREATE INDEX idx_users_email ON users(email);

-- User sessions (for JWT refresh token management)
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    session_token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address VARCHAR(45),
    user_agent TEXT
);

CREATE INDEX idx_sessions_user ON user_sessions(user_id);
CREATE INDEX idx_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_sessions_last_activity ON user_sessions(last_activity);
CREATE INDEX idx_sessions_expires_at ON user_sessions(expires_at);

-- Teams (for future workflow/task sharing within organization)
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_teams_org ON teams(organization_id);

-- Team memberships
CREATE TABLE team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member',
    added_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);

CREATE INDEX idx_team_members_team ON team_members(team_id);
CREATE INDEX idx_team_members_user ON team_members(user_id);

-- ============================================================================
-- DATA SOURCES & CONNECTIONS
-- ============================================================================

CREATE TABLE data_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    connection_config JSONB NOT NULL,
    schema_cache JSONB,
    health_status VARCHAR(20) DEFAULT 'unknown',
    last_health_check TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_datasources_org ON data_sources(organization_id);
CREATE INDEX idx_datasources_type ON data_sources(type);

CREATE TABLE data_schemas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data_source_id UUID NOT NULL REFERENCES data_sources(id),
    schema_name VARCHAR(255),
    table_name VARCHAR(255) NOT NULL,
    columns JSONB NOT NULL,
    relationships JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_schemas_datasource ON data_schemas(data_source_id);
CREATE INDEX idx_schemas_table ON data_schemas(table_name);

-- ============================================================================
-- CONVERSATIONS & CHAT HISTORY
-- ============================================================================

CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    user_id UUID NOT NULL REFERENCES users(id),
    conversation_type VARCHAR(20) NOT NULL DEFAULT 'client',
    title VARCHAR(255),
    context JSONB DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_conversations_org ON conversations(organization_id);
CREATE INDEX idx_conversations_user ON conversations(user_id);
CREATE INDEX idx_conversations_type ON conversations(conversation_type);

CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id),
    user_id UUID REFERENCES users(id),
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    parent_message_id UUID REFERENCES chat_messages(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON chat_messages(conversation_id, created_at);
CREATE INDEX idx_messages_user ON chat_messages(user_id);

CREATE TABLE message_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES chat_messages(id),
    user_id UUID NOT NULL REFERENCES users(id),
    feedback_type VARCHAR(20) NOT NULL,
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_feedback_message ON message_feedback(message_id);

-- ============================================================================
-- TASKS, WORKFLOWS & EXECUTIONS
-- ============================================================================

-- Task Modules - categories for organizing tasks by business domain
CREATE TABLE task_modules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    slug VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_org_module_slug UNIQUE (organization_id, slug)
);

CREATE INDEX idx_task_modules_org ON task_modules(organization_id);
CREATE INDEX idx_task_modules_slug ON task_modules(slug);
CREATE INDEX idx_task_modules_active ON task_modules(organization_id, is_active);

CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID REFERENCES users(id),
    conversation_id UUID REFERENCES conversations(id),
    task_type VARCHAR(20) NOT NULL,
    task_category VARCHAR(20) NOT NULL DEFAULT 'custom',
    status VARCHAR(20) DEFAULT 'draft',
    execution_mode VARCHAR(20) DEFAULT 'synchronous',
    timeout_seconds INTEGER DEFAULT 30,
    environment_profile_id UUID,
    data_source_id UUID REFERENCES data_sources(id),
    input_schema JSONB DEFAULT '{}',
    output_schema JSONB DEFAULT '{}',
    s3_bucket VARCHAR(255) NOT NULL,
    html_component_s3_key VARCHAR(500) NOT NULL,
    html_component_version_id VARCHAR(255),
    html_component_hash VARCHAR(64),
    validation_schema_s3_key VARCHAR(500) NOT NULL,
    validation_schema_version_id VARCHAR(255),
    validation_schema_hash VARCHAR(64),
    data_fetch_code_s3_key VARCHAR(500),
    data_fetch_code_version_id VARCHAR(255),
    data_fetch_code_hash VARCHAR(64),
    data_commit_code_s3_key VARCHAR(500),
    data_commit_code_version_id VARCHAR(255),
    data_commit_code_hash VARCHAR(64),
    fetch_endpoint VARCHAR(500),
    commit_endpoint VARCHAR(500),
    deployment_status VARCHAR(20) DEFAULT 'pending',
    deployed_version VARCHAR(50),
    version INTEGER DEFAULT 1,
    parent_task_id UUID REFERENCES tasks(id),
    is_latest_version BOOLEAN DEFAULT true,
    is_sandbox BOOLEAN NOT NULL DEFAULT false,
    source_task_id UUID,
    CONSTRAINT fk_tasks_source_task FOREIGN KEY (source_task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    instructions TEXT,
    is_standalone BOOLEAN NOT NULL DEFAULT true,
    module VARCHAR(50),
    avg_execution_time_ms INTEGER DEFAULT 0,
    total_executions INTEGER DEFAULT 0,
    success_rate DECIMAL(5,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT check_s3_storage CHECK (s3_bucket IS NOT NULL)
);

CREATE INDEX idx_tasks_org_type ON tasks(organization_id, task_type);
CREATE INDEX idx_tasks_status ON tasks(status) WHERE status = 'active';
CREATE INDEX idx_tasks_category ON tasks(task_category);
CREATE INDEX idx_tasks_env_profile ON tasks(environment_profile_id);
CREATE INDEX idx_tasks_is_sandbox ON tasks(is_sandbox);
CREATE INDEX idx_tasks_source_task_id ON tasks(source_task_id);
CREATE INDEX idx_tasks_module ON tasks(module);

-- Modules table: Filesystem-like organization for workflows
CREATE TABLE modules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    parent_module_id UUID REFERENCES modules(id) ON DELETE CASCADE,
    path TEXT NOT NULL, -- Full path like "/folder1/subfolder2"
    module_type VARCHAR(20) DEFAULT 'folder', -- 'folder', 'root'
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_org_path UNIQUE(organization_id, path)
);

CREATE INDEX idx_modules_org ON modules(organization_id);
CREATE INDEX idx_modules_parent ON modules(parent_module_id);
CREATE INDEX idx_modules_path ON modules(organization_id, path);

CREATE TABLE workflows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID REFERENCES users(id),
    conversation_id UUID REFERENCES conversations(id),
    status VARCHAR(20) DEFAULT 'draft',
    module_id UUID REFERENCES modules(id) ON DELETE SET NULL,
    timeout_seconds INTEGER DEFAULT 300,
    max_parallel_tasks INTEGER DEFAULT 5,
    dag_visualization JSONB,
    version INTEGER DEFAULT 1,
    parent_workflow_id UUID REFERENCES workflows(id),
    is_latest_version BOOLEAN DEFAULT true,
    is_sandbox BOOLEAN NOT NULL DEFAULT false,
    is_scheduled BOOLEAN NOT NULL DEFAULT false,
    source_workflow_id UUID,
    avg_execution_time_ms INTEGER DEFAULT 0,
    total_executions INTEGER DEFAULT 0,
    success_rate DECIMAL(5,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_workflows_source_workflow FOREIGN KEY (source_workflow_id) REFERENCES workflows(id) ON DELETE CASCADE
);

CREATE INDEX idx_workflows_user ON workflows(created_by, status);
CREATE INDEX idx_workflows_org ON workflows(organization_id);
CREATE INDEX idx_workflows_module ON workflows(module_id);
CREATE INDEX idx_workflows_is_sandbox ON workflows(is_sandbox);
CREATE INDEX idx_workflows_is_scheduled ON workflows(is_scheduled);
CREATE INDEX idx_workflows_source_workflow_id ON workflows(source_workflow_id);

-- Workflow permissions (user-scoped with explicit sharing)
CREATE TABLE workflow_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id UUID NOT NULL REFERENCES workflows(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission_level VARCHAR(20) NOT NULL, -- 'owner', 'editor', 'viewer', 'executor'
    granted_by UUID REFERENCES users(id),
    team_id UUID REFERENCES teams(id), -- NULL for direct user grants
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(workflow_id, user_id)
);

CREATE INDEX idx_workflow_permissions_workflow ON workflow_permissions(workflow_id);
CREATE INDEX idx_workflow_permissions_user ON workflow_permissions(user_id);
CREATE INDEX idx_workflow_permissions_team ON workflow_permissions(team_id);

-- Task permissions (organization-scoped with explicit user permissions)
CREATE TABLE task_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    can_view BOOLEAN DEFAULT true,
    can_edit BOOLEAN DEFAULT false,
    can_execute BOOLEAN DEFAULT false,
    can_deploy BOOLEAN DEFAULT false,
    granted_by UUID REFERENCES users(id),
    team_id UUID REFERENCES teams(id), -- NULL for direct user grants
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(task_id, user_id)
);

CREATE INDEX idx_task_permissions_task ON task_permissions(task_id);
CREATE INDEX idx_task_permissions_user ON task_permissions(user_id);
CREATE INDEX idx_task_permissions_team ON task_permissions(team_id);

-- Workflow bookmarks (user-scoped favorites)
CREATE TABLE workflow_bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workflow_id UUID NOT NULL REFERENCES workflows(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, workflow_id)
);

CREATE INDEX idx_workflow_bookmarks_user ON workflow_bookmarks(user_id);
CREATE INDEX idx_workflow_bookmarks_workflow ON workflow_bookmarks(workflow_id);
CREATE INDEX idx_workflow_bookmarks_user_created ON workflow_bookmarks(user_id, created_at DESC);

-- ============================================================================
-- LIBRARY MANAGEMENT & ENVIRONMENT PROFILES
-- ============================================================================

-- Library Registry - Approved Python libraries for sandboxed execution
CREATE TABLE library_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL,
    approved_versions TEXT[] NOT NULL DEFAULT '{}',
    description TEXT,
    category VARCHAR(100),
    security_status VARCHAR(50) DEFAULT 'safe',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_library_registry_name ON library_registry(name);
CREATE INDEX idx_library_registry_category ON library_registry(category);
CREATE INDEX idx_library_registry_active ON library_registry(is_active);

-- Environment Profiles - Pre-defined sets of libraries for task execution
CREATE TABLE environment_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    description TEXT,
    version INTEGER DEFAULT 1,
    libraries JSONB NOT NULL DEFAULT '{}',
    is_built BOOLEAN DEFAULT false,
    build_path VARCHAR(500),
    build_date TIMESTAMP WITH TIME ZONE,
    build_size_mb INTEGER,
    requirements_txt TEXT,
    last_used_at TIMESTAMP WITH TIME ZONE,
    usage_count INTEGER DEFAULT 0,
    org_id UUID REFERENCES organizations(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(name, org_id)
);

CREATE INDEX idx_environment_profiles_name ON environment_profiles(name);
CREATE INDEX idx_environment_profiles_org ON environment_profiles(org_id);
CREATE INDEX idx_environment_profiles_active ON environment_profiles(is_active);

-- Task Library Requirements - Links tasks to required libraries
CREATE TABLE task_library_requirements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    library_name VARCHAR(255) NOT NULL,
    library_version VARCHAR(50) NOT NULL,
    is_required BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(task_id, library_name)
);

CREATE INDEX idx_task_library_req_task ON task_library_requirements(task_id);
CREATE INDEX idx_task_library_req_library ON task_library_requirements(library_name);

-- Workflow Tasks - Direct association between workflows and tasks
CREATE TABLE workflow_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id UUID NOT NULL REFERENCES workflows(id) ON DELETE CASCADE,
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(workflow_id, task_id)
);

CREATE INDEX idx_workflow_tasks_workflow ON workflow_tasks(workflow_id);
CREATE INDEX idx_workflow_tasks_task ON workflow_tasks(task_id);

CREATE TABLE workflow_task_edges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id UUID NOT NULL REFERENCES workflows(id),
    source_task_id UUID NOT NULL REFERENCES tasks(id),
    target_task_id UUID NOT NULL REFERENCES tasks(id),
    edge_type VARCHAR(20) DEFAULT 'sequential',
    condition_expression TEXT,
    data_mapping JSONB,
    execution_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(workflow_id, source_task_id, target_task_id)
);

CREATE INDEX idx_workflow_edges_workflow ON workflow_task_edges(workflow_id);
CREATE INDEX idx_workflow_edges_source ON workflow_task_edges(source_task_id);
CREATE INDEX idx_workflow_edges_target ON workflow_task_edges(target_task_id);

-- Task Dependencies - navigation links between related tasks
CREATE TABLE task_dependencies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    target_task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    source_field_name VARCHAR(255),
    label VARCHAR(100) NOT NULL DEFAULT 'Create New',
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT task_dependencies_source_target_field_unique UNIQUE (source_task_id, target_task_id, source_field_name)
);

CREATE INDEX idx_task_dependencies_source ON task_dependencies(source_task_id);
CREATE INDEX idx_task_dependencies_target ON task_dependencies(target_task_id);

CREATE TABLE task_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id),
    workflow_execution_id UUID,
    scheduled_workflow_execution_id UUID,
    user_id UUID NOT NULL REFERENCES users(id),
    task_index INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    input_parameters JSONB,
    result_data JSONB,
    error_message TEXT,
    error_details JSONB,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 0,
    execution_time_ms INTEGER,
    queue_time_ms INTEGER,
    executor_instance VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Either workflow_execution_id or scheduled_workflow_execution_id should be set
    CONSTRAINT chk_execution_type CHECK (
        (workflow_execution_id IS NOT NULL AND scheduled_workflow_execution_id IS NULL) OR
        (workflow_execution_id IS NULL AND scheduled_workflow_execution_id IS NOT NULL) OR
        (workflow_execution_id IS NULL AND scheduled_workflow_execution_id IS NULL)
    )
);

CREATE INDEX idx_task_executions_task ON task_executions(task_id, created_at DESC);
CREATE INDEX idx_task_executions_workflow ON task_executions(workflow_execution_id);
CREATE INDEX idx_task_executions_scheduled_workflow ON task_executions(scheduled_workflow_execution_id);
CREATE INDEX idx_task_executions_user ON task_executions(user_id);
CREATE INDEX idx_task_executions_status ON task_executions(status);

CREATE TABLE workflow_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id UUID NOT NULL REFERENCES workflows(id),
    user_id UUID NOT NULL REFERENCES users(id),
    org_id UUID NOT NULL REFERENCES organizations(id),
    conversation_id UUID REFERENCES conversations(id),
    status VARCHAR(20) DEFAULT 'pending',
    display_name VARCHAR(255),
    input_parameters JSONB,
    result_data JSONB,
    execution_graph JSONB,
    current_tasks JSONB DEFAULT '[]',
    error_message TEXT,
    error_details JSONB,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    execution_time_ms INTEGER,
    queue_time_ms INTEGER,
    total_tasks INTEGER DEFAULT 0,
    completed_tasks INTEGER DEFAULT 0,
    worker_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_workflow_executions_workflow ON workflow_executions(workflow_id, created_at DESC);
CREATE INDEX idx_workflow_executions_user ON workflow_executions(user_id, status);
CREATE INDEX idx_workflow_executions_org ON workflow_executions(org_id);
CREATE INDEX idx_workflow_executions_status ON workflow_executions(status);

-- ============================================================================
-- AI AGENTS & AUTOMATIONS
-- ============================================================================

CREATE TABLE ai_agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    agent_type VARCHAR(50) NOT NULL,
    config JSONB NOT NULL,
    capabilities TEXT[] DEFAULT '{}',
    data_access_permissions JSONB DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'inactive',
    last_activity TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_agents_org ON ai_agents(organization_id);
CREATE INDEX idx_agents_type ON ai_agents(agent_type);
CREATE INDEX idx_agents_status ON ai_agents(status);

CREATE TABLE agent_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL REFERENCES ai_agents(id),
    activity_type VARCHAR(50) NOT NULL,
    input_data JSONB,
    output_data JSONB,
    status VARCHAR(20) DEFAULT 'pending',
    execution_time_ms INTEGER,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_activities_agent ON agent_activities(agent_id, created_at DESC);
CREATE INDEX idx_activities_status ON agent_activities(status);

CREATE TABLE scheduled_workflows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    agent_id UUID REFERENCES ai_agents(id),
    workflow_id UUID NOT NULL REFERENCES workflows(id),
    name VARCHAR(255) NOT NULL,
    schedule_expression VARCHAR(100) NOT NULL,
    timezone VARCHAR(50) DEFAULT 'UTC',
    task_config JSONB NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    last_run TIMESTAMP WITH TIME ZONE,
    next_run TIMESTAMP WITH TIME ZONE,
    run_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_scheduled_workflows_org ON scheduled_workflows(organization_id);
CREATE INDEX idx_scheduled_workflows_status ON scheduled_workflows(status);
CREATE INDEX idx_scheduled_workflows_next_run ON scheduled_workflows(next_run);

-- Scheduled workflow executions (separate from manual workflow executions)
CREATE TABLE scheduled_workflow_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scheduled_workflow_id UUID NOT NULL REFERENCES scheduled_workflows(id) ON DELETE CASCADE,
    workflow_id UUID NOT NULL REFERENCES workflows(id),
    user_id UUID NOT NULL REFERENCES users(id),
    org_id UUID NOT NULL REFERENCES organizations(id),
    status VARCHAR(20) DEFAULT 'pending',
    input_parameters JSONB,
    result_data JSONB,
    execution_graph JSONB,
    current_tasks JSONB DEFAULT '[]',
    error_message TEXT,
    error_details JSONB,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    execution_time_ms INTEGER,
    queue_time_ms INTEGER,
    total_tasks INTEGER DEFAULT 0,
    completed_tasks INTEGER DEFAULT 0,
    worker_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_scheduled_workflow_executions_scheduled ON scheduled_workflow_executions(scheduled_workflow_id, created_at DESC);
CREATE INDEX idx_scheduled_workflow_executions_workflow ON scheduled_workflow_executions(workflow_id);
CREATE INDEX idx_scheduled_workflow_executions_org ON scheduled_workflow_executions(org_id);
CREATE INDEX idx_scheduled_workflow_executions_status ON scheduled_workflow_executions(status);

-- ============================================================================
-- SECURITY & AUDIT
-- ============================================================================

CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    user_id UUID REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(255) UNIQUE NOT NULL,
    permissions JSONB DEFAULT '{}',
    expires_at TIMESTAMP WITH TIME ZONE,
    last_used TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_apikeys_org ON api_keys(organization_id);
CREATE INDEX idx_apikeys_hash ON api_keys(key_hash);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    user_email VARCHAR(255),
    action_type VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id VARCHAR(255),
    resource_name VARCHAR(255),
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    before_value JSONB,
    after_value JSONB,
    extra_data JSONB DEFAULT '{}',
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'success',
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_org_date ON audit_logs(organization_id, created_at DESC);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action_type ON audit_logs(action_type);
CREATE INDEX idx_audit_logs_resource_type ON audit_logs(resource_type);
CREATE INDEX idx_audit_logs_resource_id ON audit_logs(resource_id);

CREATE TABLE data_access_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    user_id UUID REFERENCES users(id),
    data_source_id UUID REFERENCES data_sources(id),
    table_name VARCHAR(255),
    query_hash VARCHAR(64),
    row_count INTEGER,
    execution_time_ms INTEGER,
    status VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_access_logs_org_date ON data_access_logs(organization_id, created_at DESC);
CREATE INDEX idx_access_logs_datasource ON data_access_logs(data_source_id);

-- ============================================================================
-- VECTOR DATABASE (for AI embeddings)
-- ============================================================================

CREATE TABLE document_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    document_id UUID NOT NULL,
    chunk_index INTEGER DEFAULT 0,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    embedding vector(1536),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_embeddings_vector ON document_embeddings USING hnsw (embedding vector_cosine_ops);
CREATE INDEX idx_embeddings_org ON document_embeddings(organization_id);
CREATE INDEX idx_embeddings_type ON document_embeddings(document_type);

-- ============================================================================
-- CHAT AGENT (for multi-agent conversational AI)
-- ============================================================================

-- Chat document embeddings for RAG with pgvector
CREATE TABLE chat_document_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    collection_name VARCHAR(50) NOT NULL,
    document_id VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    embedding vector(384) NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}',
    content_tsv tsvector,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT chat_document_embeddings_unique UNIQUE (collection_name, document_id)
);

CREATE INDEX idx_chat_doc_embeddings_vector ON chat_document_embeddings USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64);
CREATE INDEX idx_chat_doc_embeddings_org ON chat_document_embeddings(organization_id);
CREATE INDEX idx_chat_doc_embeddings_collection ON chat_document_embeddings(collection_name);
CREATE INDEX idx_chat_doc_embeddings_fts ON chat_document_embeddings USING gin (content_tsv);

-- Chat sessions for conversation tracking
CREATE TABLE chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    user_role VARCHAR(20) NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_chat_sessions_user ON chat_sessions(user_id);
CREATE INDEX idx_chat_sessions_org ON chat_sessions(organization_id);
CREATE INDEX idx_chat_sessions_last_active ON chat_sessions(last_active_at);

-- Conversation turns for analytics and debugging
CREATE TABLE conversation_turns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
    user_message TEXT NOT NULL,
    assistant_message TEXT NOT NULL,
    intent VARCHAR(50) NOT NULL,
    agent_type VARCHAR(50) NOT NULL,
    confidence DOUBLE PRECISION NOT NULL,
    latency_ms DOUBLE PRECISION NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_conversation_turns_session ON conversation_turns(session_id);
CREATE INDEX idx_conversation_turns_intent ON conversation_turns(intent);
CREATE INDEX idx_conversation_turns_agent ON conversation_turns(agent_type);
CREATE INDEX idx_conversation_turns_created ON conversation_turns(created_at);

-- LangChain PGVector tables for RAG (auto-managed by LangChain library)
-- These tables support multi-collection vector search with JSONB metadata filtering
CREATE TABLE langchain_pg_collection (
    name VARCHAR,
    cmetadata JSON,
    uuid UUID NOT NULL PRIMARY KEY
);

CREATE TABLE langchain_pg_embedding (
    collection_id UUID REFERENCES langchain_pg_collection(uuid) ON DELETE CASCADE,
    embedding VECTOR,
    document VARCHAR,
    cmetadata JSONB,
    custom_id VARCHAR,
    uuid UUID NOT NULL PRIMARY KEY
);

-- Index for fast JSONB metadata filtering (e.g., organization_id, workflow_id)
CREATE INDEX ix_cmetadata_gin ON langchain_pg_embedding USING gin (cmetadata jsonb_path_ops);

-- ============================================================================
-- PERFORMANCE & MONITORING
-- ============================================================================

CREATE TABLE system_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name VARCHAR(100) NOT NULL,
    metric_value DOUBLE PRECISION NOT NULL,
    tags JSONB DEFAULT '{}',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_metrics_name_time ON system_metrics(metric_name, timestamp DESC);

CREATE TABLE performance_baselines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    metric_type VARCHAR(50) NOT NULL,
    baseline_value DOUBLE PRECISION NOT NULL,
    threshold_warning DOUBLE PRECISION,
    threshold_critical DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_baselines_org ON performance_baselines(organization_id);

-- ============================================================================
-- ORGANIZATION DATA RULES (AI Data Manipulation Rules)
-- ============================================================================

-- Organization-level data rules for AI data manipulation
-- Stores system instructions, global settings, and metadata for each organization
CREATE TABLE organization_data_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,

    -- AI Instructions: General directives for AI when manipulating data
    system_instructions TEXT,

    -- Global Settings: Organization-wide defaults (currency, decimal places, etc.)
    global_settings JSONB DEFAULT '{
        "currency": "KRW",
        "decimal_places": 2,
        "date_format": "YYYY-MM-DD",
        "default_territory": null,
        "default_warehouse": null
    }'::jsonb,

    -- Active status
    is_active BOOLEAN DEFAULT true,

    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),

    UNIQUE(organization_id)
);

CREATE INDEX idx_org_data_rules_org_id ON organization_data_rules(organization_id);
CREATE INDEX idx_org_data_rules_active ON organization_data_rules(is_active);

-- DocType-specific validation rules
-- Each row defines create/update/delete rules for a specific ERPNext DocType
CREATE TABLE organization_doctype_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_data_rules_id UUID NOT NULL REFERENCES organization_data_rules(id) ON DELETE CASCADE,

    -- DocType identifier (e.g., "Item", "Customer", "Sales Order")
    doctype VARCHAR(140) NOT NULL,

    -- CREATE operation rules
    -- Structure: { enabled, required_fields[], forbidden_fields[], auto_set_fields{}, validations[] }
    create_rules JSONB DEFAULT '{
        "enabled": true,
        "required_fields": [],
        "forbidden_fields": [],
        "auto_set_fields": {},
        "validations": []
    }'::jsonb,

    -- UPDATE operation rules
    -- Structure: { enabled, protected_fields[], validations[] }
    update_rules JSONB DEFAULT '{
        "enabled": true,
        "protected_fields": [],
        "validations": []
    }'::jsonb,

    -- DELETE operation rules
    -- Structure: { enabled, forbidden, forbidden_message, require_confirmation, conditions[] }
    delete_rules JSONB DEFAULT '{
        "enabled": true,
        "forbidden": false,
        "forbidden_message": null,
        "require_confirmation": false,
        "conditions": []
    }'::jsonb,

    -- DocType-specific AI instructions
    doctype_instructions TEXT,

    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(organization_data_rules_id, doctype)
);

CREATE INDEX idx_doctype_rules_parent ON organization_doctype_rules(organization_data_rules_id);
CREATE INDEX idx_doctype_rules_doctype ON organization_doctype_rules(doctype);

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_sessions_updated_at BEFORE UPDATE ON user_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON teams FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_data_sources_updated_at BEFORE UPDATE ON data_sources FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_workflows_updated_at BEFORE UPDATE ON workflows FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_task_permissions_updated_at BEFORE UPDATE ON task_permissions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_task_executions_updated_at BEFORE UPDATE ON task_executions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_workflow_executions_updated_at BEFORE UPDATE ON workflow_executions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_ai_agents_updated_at BEFORE UPDATE ON ai_agents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_scheduled_workflows_updated_at BEFORE UPDATE ON scheduled_workflows FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_scheduled_workflow_executions_updated_at BEFORE UPDATE ON scheduled_workflow_executions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_chat_document_embeddings_updated_at BEFORE UPDATE ON chat_document_embeddings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_library_registry_updated_at BEFORE UPDATE ON library_registry FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_environment_profiles_updated_at BEFORE UPDATE ON environment_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_organization_data_rules_updated_at BEFORE UPDATE ON organization_data_rules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_organization_doctype_rules_updated_at BEFORE UPDATE ON organization_doctype_rules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add forward-referenced foreign key constraints
ALTER TABLE task_executions
ADD CONSTRAINT fk_task_exec_workflow
FOREIGN KEY (workflow_execution_id) REFERENCES workflow_executions(id);

ALTER TABLE tasks
ADD CONSTRAINT fk_task_env_profile
FOREIGN KEY (environment_profile_id) REFERENCES environment_profiles(id);
