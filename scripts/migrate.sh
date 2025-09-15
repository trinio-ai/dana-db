#!/bin/bash
# Database migration script using Atlas

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENV=${1:-docker}
ACTION=${2:-apply}

echo -e "${GREEN}DANA Database Migration Tool${NC}"
echo -e "${GREEN}=============================${NC}"
echo ""

# Validate environment
case $ENV in
    local|docker|test|production)
        echo -e "${GREEN}✓${NC} Using environment: $ENV"
        ;;
    *)
        echo -e "${RED}✗${NC} Invalid environment: $ENV"
        echo "Valid environments: local, docker, test, production"
        exit 1
        ;;
esac

# Wait for database to be ready (only for docker env)
if [ "$ENV" = "docker" ]; then
    echo -e "${YELLOW}⏳${NC} Waiting for PostgreSQL to be ready..."
    until pg_isready -h postgres -p 5432 -U dana_user; do
        sleep 1
    done
    echo -e "${GREEN}✓${NC} PostgreSQL is ready"
fi

# Change to script directory
cd "$(dirname "$0")/.."

# Execute migration based on action
case $ACTION in
    apply)
        echo -e "${GREEN}🚀${NC} Applying migrations..."
        atlas migrate apply --env $ENV --auto-approve
        echo -e "${GREEN}✅${NC} Migrations applied successfully"
        ;;
    status)
        echo -e "${GREEN}📊${NC} Migration status:"
        atlas migrate status --env $ENV
        ;;
    diff)
        echo -e "${GREEN}📋${NC} Schema diff:"
        atlas schema diff --env $ENV
        ;;
    plan)
        echo -e "${GREEN}📝${NC} Creating migration plan..."
        atlas migrate diff --env $ENV migration_$(date +%Y%m%d_%H%M%S)
        echo -e "${GREEN}✅${NC} Migration plan created"
        ;;
    validate)
        echo -e "${GREEN}🔍${NC} Validating migrations..."
        atlas migrate validate --env $ENV
        echo -e "${GREEN}✅${NC} Migrations are valid"
        ;;
    hash)
        echo -e "${GREEN}🔐${NC} Migration hash:"
        atlas migrate hash --env $ENV
        ;;
    *)
        echo -e "${RED}✗${NC} Invalid action: $ACTION"
        echo "Valid actions: apply, status, diff, plan, validate, hash"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}🎉${NC} Migration operation completed successfully!"