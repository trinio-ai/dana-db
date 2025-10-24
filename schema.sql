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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_org_slug ON organizations(slug);
CREATE INDEX idx_org_status ON organizations(status);

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

-- User sessions
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    session_token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_sessions_user ON user_sessions(user_id);
CREATE INDEX idx_sessions_token ON user_sessions(session_token);

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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON chat_messages(conversation_id, created_at);
CREATE INDEX idx_messages_user ON chat_messages(user_id);

CREATE TABLE message_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES chat_messages(id),
    user_id UUID NOT NULL REFERENCES users(id),
    feedback_type VARCHAR(20) NOT NULL,
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_feedback_message ON message_feedback(message_id);

-- ============================================================================
-- TASKS, WORKFLOWS & EXECUTIONS
-- ============================================================================

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
    erp_core_endpoint VARCHAR(255),
    deployment_status VARCHAR(20) DEFAULT 'pending',
    deployed_version VARCHAR(50),
    version INTEGER DEFAULT 1,
    parent_task_id UUID REFERENCES tasks(id),
    is_latest_version BOOLEAN DEFAULT true,
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

CREATE TABLE workflows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID REFERENCES users(id),
    conversation_id UUID REFERENCES conversations(id),
    status VARCHAR(20) DEFAULT 'draft',
    workflow_category VARCHAR(50),
    timeout_seconds INTEGER DEFAULT 300,
    max_parallel_tasks INTEGER DEFAULT 5,
    dag_visualization JSONB,
    version INTEGER DEFAULT 1,
    parent_workflow_id UUID REFERENCES workflows(id),
    is_latest_version BOOLEAN DEFAULT true,
    avg_execution_time_ms INTEGER DEFAULT 0,
    total_executions INTEGER DEFAULT 0,
    success_rate DECIMAL(5,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_workflows_user ON workflows(created_by, status);
CREATE INDEX idx_workflows_org ON workflows(organization_id);
CREATE INDEX idx_workflows_category ON workflows(workflow_category);

-- Workflow permissions (user-scoped with explicit sharing)
CREATE TABLE workflow_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id UUID NOT NULL REFERENCES workflows(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission_level VARCHAR(20) NOT NULL, -- 'owner', 'editor', 'viewer', 'executor'
    granted_by UUID REFERENCES users(id),
    team_id UUID REFERENCES teams(id), -- NULL for direct user grants
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
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
    UNIQUE(workflow_id, source_task_id, target_task_id)
);

CREATE INDEX idx_workflow_edges_workflow ON workflow_task_edges(workflow_id);
CREATE INDEX idx_workflow_edges_source ON workflow_task_edges(source_task_id);
CREATE INDEX idx_workflow_edges_target ON workflow_task_edges(target_task_id);

CREATE TABLE task_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id),
    workflow_execution_id UUID,
    user_id UUID NOT NULL REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'pending',
    input_parameters JSONB,
    result_data JSONB,
    error_message TEXT,
    error_details JSONB,
    retry_count INTEGER DEFAULT 0,
    execution_time_ms INTEGER,
    queue_time_ms INTEGER,
    erp_core_instance VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_task_executions_task ON task_executions(task_id, created_at DESC);
CREATE INDEX idx_task_executions_workflow ON task_executions(workflow_execution_id);
CREATE INDEX idx_task_executions_user ON task_executions(user_id);
CREATE INDEX idx_task_executions_status ON task_executions(status);

CREATE TABLE workflow_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id UUID NOT NULL REFERENCES workflows(id),
    user_id UUID NOT NULL REFERENCES users(id),
    conversation_id UUID REFERENCES conversations(id),
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
    worker_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_workflow_executions_workflow ON workflow_executions(workflow_id, created_at DESC);
CREATE INDEX idx_workflow_executions_user ON workflow_executions(user_id, status);
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_activities_agent ON agent_activities(agent_id, created_at DESC);
CREATE INDEX idx_activities_status ON agent_activities(status);

CREATE TABLE scheduled_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    agent_id UUID REFERENCES ai_agents(id),
    workflow_id UUID REFERENCES workflows(id),
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

CREATE INDEX idx_scheduled_tasks_org ON scheduled_tasks(organization_id);
CREATE INDEX idx_scheduled_tasks_status ON scheduled_tasks(status);
CREATE INDEX idx_scheduled_tasks_next_run ON scheduled_tasks(next_run);

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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_apikeys_org ON api_keys(organization_id);
CREATE INDEX idx_apikeys_hash ON api_keys(key_hash);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    user_id UUID REFERENCES users(id),
    event_type VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    event_data JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_org_date ON audit_logs(organization_id, created_at DESC);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_event_type ON audit_logs(event_type);

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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_embeddings_vector ON document_embeddings USING hnsw (embedding vector_cosine_ops);
CREATE INDEX idx_embeddings_org ON document_embeddings(organization_id);
CREATE INDEX idx_embeddings_type ON document_embeddings(document_type);

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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_baselines_org ON performance_baselines(organization_id);

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
CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON teams FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_data_sources_updated_at BEFORE UPDATE ON data_sources FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_workflows_updated_at BEFORE UPDATE ON workflows FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_task_permissions_updated_at BEFORE UPDATE ON task_permissions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_task_executions_updated_at BEFORE UPDATE ON task_executions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_workflow_executions_updated_at BEFORE UPDATE ON workflow_executions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_ai_agents_updated_at BEFORE UPDATE ON ai_agents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_scheduled_tasks_updated_at BEFORE UPDATE ON scheduled_tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add forward-referenced foreign key constraints
ALTER TABLE task_executions 
ADD CONSTRAINT fk_task_exec_workflow 
FOREIGN KEY (workflow_execution_id) REFERENCES workflow_executions(id);
