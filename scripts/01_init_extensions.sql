-- Initialize required PostgreSQL extensions for DANA
-- This script runs automatically when the postgres container is first created

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pgcrypto for encryption
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enable vector for embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable full-text search extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- Create development database for Atlas schema migrations
CREATE DATABASE dana_dev WITH OWNER dana_user;

-- Connect to dev database and enable extensions there too
\c dana_dev
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;