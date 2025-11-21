#!/bin/bash
# DANA Database Reset Script
# This script completely resets the dana database:
# 1. Drops and recreates the database
# 2. Applies all migrations from scratch
# 3. Seeds initial data (libraries, test organizations, users)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Database connection details
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-dana}"
DB_USER="${DB_USER:-dana_user}"
DB_PASSWORD="${DB_PASSWORD:-dana_password}"
POSTGRES_DB="postgres"

echo -e "${RED}⚠️  WARNING: This will completely reset the DANA database!${NC}"
echo -e "${YELLOW}All existing data will be lost.${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}DANA Database Reset${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Step 1: Drop and recreate database
echo -e "${BLUE}Step 1/4: Dropping and recreating database...${NC}"
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $POSTGRES_DB <<EOF
-- Terminate existing connections
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();

-- Drop and recreate database
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME;
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database recreated${NC}"
else
    echo -e "${RED}❌ Failed to recreate database${NC}"
    exit 1
fi
echo ""

# Step 2: Apply all migrations
echo -e "${BLUE}Step 2/4: Applying migrations...${NC}"
cd "$(dirname "$0")/.."  # Go to dana-db directory
atlas migrate apply --env local --auto-approve

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ All migrations applied${NC}"
else
    echo -e "${RED}❌ Migration failed${NC}"
    exit 1
fi
echo ""

# Step 3: Seed library data
echo -e "${BLUE}Step 3/4: Seeding library registry data...${NC}"
if [ -f "seed_library_data.sql" ]; then
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f seed_library_data.sql > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Library data seeded${NC}"
    else
        echo -e "${YELLOW}⚠️  Library data seeding had warnings (might be okay)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  seed_library_data.sql not found, skipping${NC}"
fi
echo ""

# Step 4: Seed test data (organizations and users)
echo -e "${BLUE}Step 4/4: Creating test organization and users...${NC}"
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME <<'EOF'
-- Create test organization
INSERT INTO organizations (id, name, slug, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000001'::uuid,
    'Test Organization',
    'test-org',
    NOW(),
    NOW()
) ON CONFLICT (slug) DO NOTHING;

-- Create admin user
INSERT INTO users (id, email, username, password_hash, organization_id, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000101'::uuid,
    'admin@test-org.com',
    'admin',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqVz.UzKZK',  -- password: admin123
    '00000000-0000-0000-0000-000000000001'::uuid,
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- Create regular user
INSERT INTO users (id, email, username, password_hash, organization_id, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000102'::uuid,
    'user@test-org.com',
    'user',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqVz.UzKZK',  -- password: admin123
    '00000000-0000-0000-0000-000000000001'::uuid,
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- Create test team
INSERT INTO teams (id, name, organization_id, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000201'::uuid,
    'Engineering',
    '00000000-0000-0000-0000-000000000001'::uuid,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Add admin user to team
INSERT INTO team_members (team_id, user_id, role, created_at)
VALUES (
    '00000000-0000-0000-0000-000000000201'::uuid,
    '00000000-0000-0000-0000-000000000101'::uuid,
    'admin',
    NOW()
) ON CONFLICT DO NOTHING;

-- Verify data
SELECT
    'Organizations' as table_name,
    COUNT(*)::text as count
FROM organizations
UNION ALL
SELECT 'Users', COUNT(*)::text FROM users
UNION ALL
SELECT 'Teams', COUNT(*)::text FROM teams
UNION ALL
SELECT 'Team Members', COUNT(*)::text FROM team_members
UNION ALL
SELECT 'Libraries', COUNT(*)::text FROM library_registry;
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Test data created${NC}"
else
    echo -e "${RED}❌ Failed to create test data${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}✅ Database Reset Complete!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${BLUE}📊 Database Information:${NC}"
echo -e "  • Database: ${GREEN}$DB_NAME${NC}"
echo -e "  • Host: ${GREEN}$DB_HOST:$DB_PORT${NC}"
echo -e "  • User: ${GREEN}$DB_USER${NC}"
echo ""
echo -e "${BLUE}🔐 Test Credentials:${NC}"
echo -e "  • Admin: ${GREEN}admin@test-org.com${NC} / ${YELLOW}admin123${NC}"
echo -e "  • User:  ${GREEN}user@test-org.com${NC} / ${YELLOW}admin123${NC}"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo -e "  1. Start services: ${GREEN}make core-up${NC}"
echo -e "  2. Access API docs: ${GREEN}http://localhost:8001/docs${NC}"
echo -e "  3. Login with test credentials above"
echo ""
