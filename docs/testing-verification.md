# Testing & Verification

This document covers testing procedures and verification steps for the DANA database setup.

## 🧪 End-to-End Migration Testing

### Complete teardown and fresh setup verification

```bash
# 1. Complete environment teardown
docker-compose down --remove-orphans -v
docker system prune -f

# 2. Fresh start verification
make dev-data                  # Should create fresh database with all extensions
make db-migrate-status         # Should show current migration state
make db-shell                  # Verify tables and extensions exist

# 3. Verify data integration tables
# Inside PostgreSQL shell:
\dt integration*               # Should show all 6 integration tables
\dx                           # Should show all extensions including vector
```

## Schema Verification Commands

### Check Tables and Extensions

```bash
# Check all tables were created
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "\dt"

# Verify extensions are enabled
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "\dx"

# Check specific integration tables
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'integration_%';"

# Verify foreign key constraints
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "SELECT conname, conrelid::regclass AS table_name, confrelid::regclass AS referenced_table FROM pg_constraint WHERE contype = 'f' AND conrelid::regclass::text LIKE 'integration_%';"
```

### Verify Data Integration Engine Tables

```bash
# Check integration_connections table structure
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "\d integration_connections"

# Check integration_query_logs indexes
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "\d integration_query_logs"

# Verify schema cache table
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "\d integration_schema_cache"
```

## Migration Health Checks

### Atlas Migration Validation

```bash
# Atlas migration integrity check
make db-migrate-validate       # Validates migration file integrity

# Database schema comparison
atlas schema diff --env docker # Compare actual vs expected schema

# Migration history review
atlas migrate status --env docker --format '{{ json . }}'

# Check migration hash
make db-migrate-hash
```

### Connection Testing

```bash
# Test database connectivity
pg_isready -h localhost -p 5432 -U dana_user

# Check Docker network
docker-compose ps postgres

# Test connection from container
docker exec dana-local-dev-postgres-1 pg_isready -U dana_user
```

## Performance Testing

### Query Performance

```bash
# Test query execution on integration tables
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "EXPLAIN ANALYZE SELECT * FROM integration_connections WHERE organization_id = '00000000-0000-0000-0000-000000000000';"

# Check index usage
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch FROM pg_stat_user_indexes WHERE tablename LIKE 'integration_%';"
```

### Connection Pool Testing

```bash
# Check connection limits
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "SHOW max_connections;"

# Monitor active connections
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "SELECT count(*) FROM pg_stat_activity;"
```

## Data Integrity Testing

### Foreign Key Constraints

```bash
# Test organization foreign key constraint
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "INSERT INTO integration_connections (id, organization_id, name, type) VALUES ('test-1', '99999999-9999-9999-9999-999999999999', 'Test Connection', 'postgresql');" 2>&1 || echo "Foreign key constraint working correctly"

# Test cascade deletes (use with caution)
# Create test data first, then test cascade behavior
```

### Data Types and Constraints

```bash
# Test UUID generation
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "SELECT gen_random_uuid();"

# Test JSONB columns
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "SELECT '{}' :: jsonb;"

# Test timestamp defaults
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "SELECT NOW();"
```

## Extension Testing

### Vector Extension

```bash
# Test vector extension functionality
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "SELECT '[1,2,3]'::vector;"

# Test vector operations
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "SELECT '[1,2,3]'::vector <-> '[4,5,6]'::vector as distance;"
```

### Other Extensions

```bash
# Test uuid-ossp
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "SELECT uuid_generate_v4();"

# Test pgcrypto
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "SELECT gen_random_uuid();"

# Test pg_trgm
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "SELECT similarity('test', 'testing');"
```

## Troubleshooting Common Issues

### Migration Failures

```bash
# Check migration status
make db-migrate-status

# Review migration logs
docker-compose logs postgres

# Check for schema conflicts
atlas schema diff --env docker
```

### Connection Issues

```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# Check PostgreSQL logs
docker-compose logs postgres

# Test network connectivity
docker exec dana-local-dev-postgres-1 ping postgres
```

### Extension Issues

```bash
# List installed extensions
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "\dx"

# Check extension availability
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "SELECT * FROM pg_available_extensions WHERE name IN ('vector', 'uuid-ossp', 'pgcrypto');"

# Manually install missing extensions
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

## Automated Testing Scripts

### Health Check Script

```bash
#!/bin/bash
# health-check.sh
set -e

echo "Testing database health..."

# Test connection
pg_isready -h localhost -p 5432 -U dana_user || exit 1

# Test extensions
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "\dx" | grep -q vector || exit 1

# Test tables
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "\dt" | grep -q integration_connections || exit 1

echo "Database health check passed!"
```

### Schema Validation Script

```bash
#!/bin/bash
# validate-schema.sh
set -e

echo "Validating schema..."

# Run Atlas validation
atlas migrate validate --env docker || exit 1

# Check schema drift
atlas schema diff --env docker > /tmp/schema_diff.txt
if [ -s /tmp/schema_diff.txt ]; then
    echo "Schema drift detected:"
    cat /tmp/schema_diff.txt
    exit 1
fi

echo "Schema validation passed!"
```

## Continuous Integration Testing

### GitHub Actions Example

```yaml
name: Database Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: pgvector/pgvector:pg16
        env:
          POSTGRES_USER: dana_user
          POSTGRES_PASSWORD: dana_password
          POSTGRES_DB: dana
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
      - name: Install Atlas
        run: |
          curl -sSf https://atlasgo.sh | sh
      - name: Run migrations
        run: |
          cd dana-db
          atlas migrate apply --env local
      - name: Validate schema
        run: |
          cd dana-db
          atlas migrate validate --env local
```

This comprehensive testing framework ensures database reliability and helps catch issues early in the development process.