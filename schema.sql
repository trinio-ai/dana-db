-- DANA OS Database Schema
-- Based on PRD v2.0 specification
-- This is the master schema definition for the entire DANA platform

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";

-- ============================================================================
-- ORGANIZATIONS & USERS
-- ============================================================================

-- Organizations (Multi-tenant)
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    plan_type VARCHAR(50) NOT NULL DEFAULT 'starter',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Users
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'member',
    permissions JSONB DEFAULT '{}',
    preferences JSONB DEFAULT '{}',
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User sessions
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- DATA SOURCES & CONNECTIONS
-- ============================================================================

-- Data sources
CREATE TABLE IF NOT EXISTS data_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'postgres', 'mysql', 'bigquery', 'snowflake', etc.
    connection_config JSONB NOT NULL, -- Encrypted connection details
    schema_cache JSONB, -- Cached schema information
    health_status VARCHAR(20) DEFAULT 'unknown',
    last_health_check TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Data source schemas (cached)
CREATE TABLE IF NOT EXISTS data_schemas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data_source_id UUID NOT NULL REFERENCES data_sources(id) ON DELETE CASCADE,
    schema_name VARCHAR(255),
    table_name VARCHAR(255) NOT NULL,
    columns JSONB NOT NULL, -- Column definitions
    relationships JSONB DEFAULT '{}', -- Foreign key relationships
    metadata JSONB DEFAULT '{}', -- Additional metadata
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- CONVERSATIONS & CHAT HISTORY
-- ============================================================================

-- Conversations
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255),
    context JSONB DEFAULT '{}', -- Conversation context and state
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Chat messages
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- NULL for system messages
    role VARCHAR(20) NOT NULL, -- 'user', 'assistant', 'system'
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}', -- Message metadata, attachments, etc.
    parent_message_id UUID REFERENCES chat_messages(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Message reactions and feedback
CREATE TABLE IF NOT EXISTS message_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    feedback_type VARCHAR(20) NOT NULL, -- 'thumbs_up', 'thumbs_down', 'flag'
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- WORKFLOWS & EXECUTIONS
-- ============================================================================

-- Workflows (extends existing schema)
CREATE TABLE IF NOT EXISTS workflows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    user_id VARCHAR(255) NOT NULL, -- Creator
    conversation_id UUID REFERENCES conversations(id) ON DELETE SET NULL,
    workflow_type VARCHAR(50) NOT NULL DEFAULT 'general',
    status VARCHAR(20) DEFAULT 'draft',

    -- Workflow definition
    user_prompt TEXT NOT NULL,
    database_context JSONB,
    input_form JSONB,
    operation_code JSONB NOT NULL,
    output_template JSONB,
    validation_rules JSONB DEFAULT '[]',

    -- Metadata
    tags TEXT[] DEFAULT '{}',
    version INTEGER DEFAULT 1,
    parent_workflow_id UUID REFERENCES workflows(id) ON DELETE SET NULL,
    is_latest_version BOOLEAN DEFAULT true,

    -- Performance metrics
    avg_execution_time_ms INTEGER DEFAULT 0,
    total_executions INTEGER DEFAULT 0,
    success_rate DECIMAL(5,2) DEFAULT 0.00,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Workflow executions (extends existing schema)
CREATE TABLE IF NOT EXISTS workflow_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id UUID NOT NULL REFERENCES workflows(id) ON DELETE CASCADE,
    user_id VARCHAR(255) NOT NULL,
    conversation_id UUID REFERENCES conversations(id) ON DELETE SET NULL,

    -- Execution details
    status VARCHAR(20) DEFAULT 'pending',
    priority VARCHAR(10) DEFAULT 'normal',
    input_parameters JSONB,
    result_data JSONB,

    -- Error handling
    error_message TEXT,
    error_details JSONB,
    retry_count INTEGER DEFAULT 0,
    parent_execution_id UUID REFERENCES workflow_executions(id) ON DELETE SET NULL,

    -- Performance metrics
    execution_time_ms INTEGER,
    queue_time_ms INTEGER,
    memory_used_mb INTEGER,
    cpu_used_percent DECIMAL(5,2),
    worker_id VARCHAR(255),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- AI AGENTS & AUTOMATIONS
-- ============================================================================

-- AI Agents
CREATE TABLE IF NOT EXISTS ai_agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    agent_type VARCHAR(50) NOT NULL, -- 'scheduler', 'monitor', 'analyst', etc.

    -- Agent configuration
    config JSONB NOT NULL, -- Agent-specific configuration
    capabilities TEXT[] DEFAULT '{}', -- What the agent can do
    data_access_permissions JSONB DEFAULT '{}', -- Data access rules

    -- State
    status VARCHAR(20) DEFAULT 'inactive',
    last_activity TIMESTAMP WITH TIME ZONE,

    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Agent executions/activities
CREATE TABLE IF NOT EXISTS agent_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL REFERENCES ai_agents(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL, -- 'scheduled_report', 'anomaly_detected', etc.

    -- Activity details
    input_data JSONB,
    output_data JSONB,
    status VARCHAR(20) DEFAULT 'pending',

    -- Execution metrics
    execution_time_ms INTEGER,
    error_message TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Scheduled tasks
CREATE TABLE IF NOT EXISTS scheduled_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    agent_id UUID REFERENCES ai_agents(id) ON DELETE SET NULL,
    workflow_id UUID REFERENCES workflows(id) ON DELETE SET NULL,

    -- Schedule configuration
    name VARCHAR(255) NOT NULL,
    schedule_expression VARCHAR(100) NOT NULL, -- Cron expression
    timezone VARCHAR(50) DEFAULT 'UTC',

    -- Task details
    task_config JSONB NOT NULL,
    status VARCHAR(20) DEFAULT 'active',

    -- Execution tracking
    last_run TIMESTAMP WITH TIME ZONE,
    next_run TIMESTAMP WITH TIME ZONE,
    run_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,

    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- SECURITY & AUDIT
-- ============================================================================

-- API keys and tokens
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,

    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(255) UNIQUE NOT NULL,
    permissions JSONB DEFAULT '{}',

    expires_at TIMESTAMP WITH TIME ZONE,
    last_used TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'active',

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Audit log
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Event details
    event_type VARCHAR(50) NOT NULL, -- 'user_login', 'workflow_executed', etc.
    resource_type VARCHAR(50), -- 'workflow', 'data_source', etc.
    resource_id UUID,

    -- Event data
    event_data JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Data access logs
CREATE TABLE IF NOT EXISTS data_access_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Access details
    data_source_id UUID REFERENCES data_sources(id) ON DELETE SET NULL,
    table_name VARCHAR(255),
    query_hash VARCHAR(64), -- Hash of the executed query
    row_count INTEGER,

    -- Execution details
    execution_time_ms INTEGER,
    status VARCHAR(20),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- VECTOR EMBEDDINGS (for AI/ML features)
-- ============================================================================

-- Document embeddings for semantic search
CREATE TABLE IF NOT EXISTS document_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,

    -- Document metadata
    document_type VARCHAR(50) NOT NULL, -- 'workflow', 'conversation', 'schema', etc.
    document_id UUID NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',

    -- Vector embedding
    embedding vector(1536), -- OpenAI ada-002 dimensions

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- PERFORMANCE & MONITORING
-- ============================================================================

-- System metrics
CREATE TABLE IF NOT EXISTS system_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name VARCHAR(100) NOT NULL,
    metric_value DOUBLE PRECISION NOT NULL,
    tags JSONB DEFAULT '{}',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Performance baselines
CREATE TABLE IF NOT EXISTS performance_baselines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    metric_type VARCHAR(50) NOT NULL,
    baseline_value DOUBLE PRECISION NOT NULL,
    threshold_warning DOUBLE PRECISION,
    threshold_critical DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Organization indexes
CREATE INDEX idx_organizations_slug ON organizations(slug);

-- User indexes
CREATE INDEX idx_users_organization_id ON users(organization_id);
CREATE INDEX idx_users_email ON users(email);

-- Session indexes
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_user_sessions_expires ON user_sessions(expires_at);

-- Data source indexes
CREATE INDEX idx_data_sources_organization_id ON data_sources(organization_id);
CREATE INDEX idx_data_schemas_data_source_id ON data_schemas(data_source_id);

-- Conversation indexes
CREATE INDEX idx_conversations_user_id ON conversations(user_id);
CREATE INDEX idx_conversations_status ON conversations(status);
CREATE INDEX idx_chat_messages_conversation_id ON chat_messages(conversation_id);
CREATE INDEX idx_message_feedback_message_id ON message_feedback(message_id);

-- Workflow indexes
CREATE INDEX idx_workflows_organization_id ON workflows(organization_id);
CREATE INDEX idx_workflows_status ON workflows(status);
CREATE INDEX idx_workflows_conversation_id ON workflows(conversation_id);
CREATE INDEX idx_workflow_executions_workflow_id ON workflow_executions(workflow_id);
CREATE INDEX idx_workflow_executions_status ON workflow_executions(status);
CREATE INDEX idx_workflow_executions_created_at ON workflow_executions(created_at);

-- AI Agent indexes
CREATE INDEX idx_ai_agents_organization_id ON ai_agents(organization_id);
CREATE INDEX idx_ai_agents_type ON ai_agents(agent_type);
CREATE INDEX idx_agent_activities_agent_id ON agent_activities(agent_id);
CREATE INDEX idx_scheduled_tasks_organization_id ON scheduled_tasks(organization_id);
CREATE INDEX idx_scheduled_tasks_next_run ON scheduled_tasks(next_run);

-- Security indexes
CREATE INDEX idx_api_keys_organization_id ON api_keys(organization_id);
CREATE INDEX idx_api_keys_key_hash ON api_keys(key_hash);
CREATE INDEX idx_audit_logs_organization_id ON audit_logs(organization_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_data_access_logs_organization_id ON data_access_logs(organization_id);
CREATE INDEX idx_data_access_logs_created_at ON data_access_logs(created_at);

-- Vector search index
CREATE INDEX ON document_embeddings USING hnsw (embedding vector_cosine_ops);

-- Performance indexes
CREATE INDEX idx_system_metrics_name_timestamp ON system_metrics(metric_name, timestamp);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all relevant tables
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_data_sources_updated_at BEFORE UPDATE ON data_sources
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workflows_updated_at BEFORE UPDATE ON workflows
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workflow_executions_updated_at BEFORE UPDATE ON workflow_executions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_agents_updated_at BEFORE UPDATE ON ai_agents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_scheduled_tasks_updated_at BEFORE UPDATE ON scheduled_tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();