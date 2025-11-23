-- PostgreSQL initialization script for DANA database
-- This runs automatically on first database startup

-- Create atlas_dev database for Atlas migrations
CREATE DATABASE atlas_dev;

-- Connect to atlas_dev and install vector extension
\c atlas_dev;
CREATE EXTENSION IF NOT EXISTS vector;

-- Switch back to dana database for main setup
\c dana;
CREATE EXTENSION IF NOT EXISTS vector;
