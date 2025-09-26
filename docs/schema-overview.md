# DANA Database Schema Overview

This document provides a comprehensive overview of the DANA database schema, including all tables and their relationships.

## Core Tables

The master schema is defined in `schema.sql` and follows the DANA PRD v2.0 specification. It includes:

### Organizations & Users
- **Organizations**: Multi-tenant user management
- **Users**: User accounts and profiles
- **API Keys**: Authentication and access control

### Data Sources & Integration
- **Data Sources**: External data connection management
- **Integration Connections**: Database connection configurations and status tracking
- **Integration Connection Tests**: Connection health monitoring and diagnostics
- **Integration Database Contexts**: Cached database schema and metadata contexts
- **Integration Query Logs**: Detailed logging of all query executions
- **Integration Query Metrics**: Performance metrics and statistics for query optimization
- **Integration Schema Cache**: Cached database schema information including tables, columns, and relationships

### Conversations & Chat
- **Conversations**: Chat history and context
- **Chat Messages**: Individual messages within conversations

### Workflows & AI
- **Workflows**: Workflow definitions and executions
- **Workflow Executions**: Runtime execution tracking
- **AI Agents**: Autonomous agent management

### Security & Audit
- **Audit Logs**: Comprehensive logging and tracking
- **Security events**: Access control and monitoring

## Data Integration Engine Tables

The data integration engine provides universal data access across organizational data sources. The following tables support this functionality:

### `integration_connections`
Database connection configurations with status tracking and encrypted credential storage.

**Key Features:**
- Supports multiple database types (PostgreSQL, MySQL, etc.)
- Encrypted configuration storage
- Connection status monitoring
- Capability tracking

### `integration_connection_tests`
Health monitoring and diagnostic information for database connections.

**Key Features:**
- Success/failure tracking
- Response time monitoring
- Server version detection
- Error message logging
- Connection pool status

### `integration_database_contexts`
Cached database schema and metadata contexts for organizations.

**Key Features:**
- Schema version tracking
- JSONB context data storage
- Cache expiration management
- Organization-scoped contexts

### `integration_query_logs`
Detailed logging of all query executions for audit and performance analysis.

**Key Features:**
- Query hash for deduplication
- Execution time tracking
- Success/failure status
- User and request tracking
- Error logging

### `integration_query_metrics`
Aggregated performance metrics for query optimization.

**Key Features:**
- Query pattern analysis
- Average/min/max execution times
- Success rate tracking
- Execution count statistics

### `integration_schema_cache`
Cached database schema information including tables, columns, and relationships.

**Key Features:**
- Table and column metadata
- Index and foreign key information
- Trigger and relationship mapping
- Row count and size tracking
- Cache expiration management

## Schema Features

- **UUID Primary Keys**: For distributed system compatibility
- **JSONB Columns**: For flexible metadata storage
- **Vector Support**: For AI/ML embeddings using pgvector
- **Audit Trails**: Comprehensive logging and tracking
- **Performance Indexes**: Optimized for common query patterns
- **Triggers**: Automatic timestamp updates
- **Foreign Key Constraints**: Data integrity enforcement
- **Multi-tenant Isolation**: Organization-based data separation

## Indexes and Performance

The schema includes comprehensive indexing for:
- Organization-based queries
- Time-based filtering
- Status and type lookups
- Query pattern analysis
- Cache expiration management

## Security Considerations

- **Row-level Security**: Organization-based access control
- **Encrypted Storage**: Sensitive configuration data
- **Audit Logging**: Complete operation tracking
- **Foreign Key Constraints**: Data integrity protection