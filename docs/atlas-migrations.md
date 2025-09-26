# Atlas Migration System

This document explains how the Atlas migration system works in the DANA project, including our self-contained extension approach.

## 🔧 How Atlas Migrations Work

### Self-Contained Extension Management

**Key Innovation**: Our migrations are **self-contained** and automatically create required PostgreSQL extensions.

#### The Extension Challenge
Atlas uses ephemeral "dev databases" for migration validation, which get dropped/recreated on each run. Standard postgres images don't include pgvector, causing migration failures.

#### Our Solution
Migration files include extension creation at the beginning:

```sql
-- migrations/20250915195954_initial.sql
-- Create required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Then create tables...
CREATE TABLE "public"."organizations" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  -- ...
);
```

#### Benefits
- ✅ **Repeatable**: Works on any fresh PostgreSQL instance
- ✅ **Self-Contained**: No manual extension setup required
- ✅ **Dev-Friendly**: New users get working database instantly
- ✅ **CI/CD Ready**: Automated deployment without manual steps

### Atlas Configuration

```hcl
# atlas.hcl - Multi-environment configuration
env "docker" {
  src = "file://schema.sql"
  url = "postgresql://dana_user:dana_password@postgres:5432/dana?sslmode=disable"
  dev = "postgresql://dana_user:dana_password@postgres:5432/dana_dev?sslmode=disable"

  migration {
    dir = "file://migrations"
  }
}

env "local" {
  src = "file://schema.sql"
  url = "postgresql://dana_user:dana_password@localhost:5432/dana?sslmode=disable"
  dev = "postgresql://dana_user:dana_password@localhost:5432/atlas_dev?sslmode=disable"

  migration {
    dir = "file://migrations"
  }
}
```

### Migration Generation Process

1. **Schema Update**: Modify `schema.sql` with new tables/columns
2. **Atlas Diff**: `atlas migrate diff new_feature --env local`
3. **Extension Handling**: Atlas reads existing migration extensions
4. **Clean Generation**: Produces minimal, focused migration files
5. **Validation**: Tests against dev database with extensions

## Migration Workflow

### 1. Modify Schema

Edit `schema.sql` with your changes:

```sql
-- Add new table
CREATE TABLE new_feature (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. Generate Migration

```bash
# Generate migration file
make db-migrate-plan

# Or using Atlas directly
atlas migrate diff --env docker migration_add_new_feature
```

### 3. Review Migration

Check the generated migration in `migrations/` directory:

```sql
-- migration file example
-- Create "new_feature" table
CREATE TABLE "public"."new_feature" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "name" character varying(255) NOT NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id")
);
```

### 4. Apply Migration

```bash
# Apply to local development
make db-migrate

# Apply to specific environment
./scripts/migrate.sh docker apply
```

### 5. Validate

```bash
# Check migration status
make db-migrate-status

# Validate integrity
make db-migrate-validate
```

## Environment Configuration

The Atlas configuration supports multiple environments:

- **local**: For local development (postgres on localhost)
- **docker**: For Docker Compose development (postgres container)
- **test**: For testing environments
- **production**: For production deployments

## Best Practices

### Development Workflow

1. **Design**: Plan your schema changes
2. **Update**: Modify `schema.sql` with new tables/columns
3. **Generate**: Create migration using `make db-migrate-plan`
4. **Review**: Examine generated migration file
5. **Test**: Apply migration to test environment
6. **Apply**: Apply to development environment
7. **Commit**: Add migration files to version control

### Migration Guidelines

- **Incremental Changes**: Make small, focused schema changes
- **Backward Compatibility**: Ensure migrations don't break existing code
- **Test Migrations**: Always test on non-production data first
- **Document Changes**: Include clear descriptions in migration files
- **Review Process**: Have schema changes reviewed before applying

### Rollback Strategy

Atlas doesn't support automatic rollbacks. For rollback capability:

1. **Manual Rollback**: Create reverse migration manually
2. **Backup First**: Always backup before major changes
3. **Test Rollbacks**: Test rollback procedures in development

## Troubleshooting

### Common Issues

#### pgvector Extension Missing
```bash
# Error: pq: type "public.vector" does not exist
# Solution: Enable pgvector extension
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

#### Atlas Schema Revisions Conflict
```bash
# Error: connected database is not clean: found schema "atlas_schema_revisions"
# Solution: Clean Atlas state before generating initial migration
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "DROP SCHEMA IF EXISTS atlas_schema_revisions CASCADE;"
```

#### Migration Failed
```bash
# Check migration status
atlas migrate status --env docker

# Review migration logs
docker-compose logs dana-db-migrate
```

#### Schema Drift
```bash
# Compare current schema with expected
atlas schema diff --env docker

# Reset to known state (development only)
make db-reset
```

## Production Deployment

### Prerequisites

- PostgreSQL database with required extensions
- Atlas CLI installed on deployment server
- Database credentials configured

### Environment Variables

```bash
export DATABASE_URL="postgresql://user:pass@host:port/db?sslmode=require"
export ATLAS_ENV="production"
```

### Deployment Process

```bash
# 1. Validate migrations
atlas migrate validate --env production

# 2. Check status
atlas migrate status --env production

# 3. Apply migrations
atlas migrate apply --env production --auto-approve

# 4. Verify
atlas migrate status --env production
```

## Security Considerations

- **Credentials**: Never commit database credentials to version control
- **Encryption**: Use SSL/TLS for database connections in production
- **Access Control**: Limit database access to authorized personnel only
- **Audit**: Monitor and log all schema changes
- **Backup**: Maintain regular backups before schema changes