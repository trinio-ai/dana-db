-- Initial database setup: Install required PostgreSQL extensions
-- This must run before any table migrations

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable cryptographic functions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enable vector similarity search (pgvector)
CREATE EXTENSION IF NOT EXISTS "vector";
