#!/bin/bash

# Setup script for Atlas dev database with required extensions
echo "Setting up Atlas dev database with extensions..."

# Create dana_dev database if it doesn't exist
docker exec dana-local-dev-postgres-1 psql -U dana_user -d postgres -c "SELECT 1 FROM pg_database WHERE datname = 'dana_dev'" | grep -q 1
if [ $? -ne 0 ]; then
    echo "Creating dana_dev database..."
    docker exec dana-local-dev-postgres-1 psql -U dana_user -d postgres -c "CREATE DATABASE dana_dev WITH OWNER dana_user;"
fi

# Install required extensions
echo "Installing required extensions in dana_dev..."
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana_dev -c "
CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;
"

echo "Dev database setup complete!"