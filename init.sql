-- PostgreSQL initialization script for DANA database
-- This runs automatically on first database startup

-- Install extensions in the main dana database
-- (database is created by POSTGRES_DB env var)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";

-- Create dana_dev database for Atlas migrations (clean dev environment)
CREATE DATABASE dana_dev;

-- Connect to dana_dev and install required extensions
\c dana_dev
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";
