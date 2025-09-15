# DANA Database Management

This directory contains the centralized database schema and migration management for the entire DANA platform using [Atlas](https://atlasgo.io/).

## Structure

```
dana-db/
├── atlas.hcl          # Atlas configuration file
├── schema.sql         # Master database schema
├── migrations/        # Generated migration files
├── scripts/           # Helper scripts
│   └── migrate.sh     # Migration management script
├── config/           # Configuration files
└── Dockerfile        # Atlas container for migrations
```

## Quick Start

### First-Time Setup (Initial Database Creation)

If you're setting up the database for the first time or need to recreate the initial migration:

#### Prerequisites

1. **Start PostgreSQL**: Ensure PostgreSQL is running via Docker Compose
   ```bash
   docker-compose up -d postgres
   ```

2. **Install Atlas CLI** (if not already installed)
   ```bash
   # macOS
   brew install ariga/tap/atlas

   # Linux/Unix
   curl -sSf https://atlasgo.sh | sh
   ```

#### Initial Setup Process

1. **Navigate to dana-db directory**
   ```bash
   cd dana-db
   ```

2. **Clean existing Atlas state** (if database has been used before)
   ```bash
   docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "DROP SCHEMA IF EXISTS atlas_schema_revisions CASCADE;"
   ```

3. **Generate initial migration from schema**
   ```bash
   atlas migrate diff initial --env local --dev-url "postgresql://dana_user:dana_password@localhost:5432/dana?sslmode=disable"
   ```

4. **Apply the initial migration**
   ```bash
   atlas migrate apply --env local
   ```

5. **Verify setup**
   ```bash
   # Check tables were created
   docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "\dt"

   # Check extensions are enabled
   docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "\dx"
   ```

**Note**: For clean database setups, PostgreSQL extensions (uuid-ossp, vector, pg_trgm, btree_gin) are automatically enabled via the initialization script in `scripts/01_init_extensions.sql`. This ensures the pgvector extension is available for embeddings without manual intervention.

### Regular Usage (After Initial Setup)

#### Using Docker (Recommended for local development)

```bash
# Apply migrations in docker environment
make db-migrate

# Check migration status
make db-migrate-status

# Generate new migration
make db-migrate-plan

# Validate migrations
make db-migrate-validate
```

#### Using Atlas CLI directly

```bash
# Apply migrations
atlas migrate apply --env docker

# Check status
atlas migrate status --env docker

# Generate new migration
atlas migrate diff --env docker migration_$(date +%Y%m%d_%H%M%S)
```

## Environments

The Atlas configuration supports multiple environments:

- **local**: For local development (postgres on localhost)
- **docker**: For Docker Compose development (postgres container)
- **test**: For testing environments
- **production**: For production deployments

## Schema Management

The master schema is defined in `schema.sql` and follows the DANA PRD v2.0 specification. It includes:

### Core Tables

- **Organizations & Users**: Multi-tenant user management
- **Data Sources**: External data connection management
- **Conversations**: Chat history and context
- **Workflows**: Workflow definitions and executions
- **AI Agents**: Autonomous agent management
- **Security**: API keys, audit logs, and access control

### Features

- **UUID Primary Keys**: For distributed system compatibility
- **JSONB Columns**: For flexible metadata storage
- **Vector Support**: For AI/ML embeddings using pgvector
- **Audit Trails**: Comprehensive logging and tracking
- **Performance Indexes**: Optimized for common query patterns
- **Triggers**: Automatic timestamp updates
- **Auto-initialization**: PostgreSQL extensions are automatically enabled via init scripts

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

## Common Commands

```bash
# Database setup and migration
make db-migrate              # Apply migrations
make db-migrate-status       # Check migration status
make db-migrate-plan         # Generate new migration
make db-migrate-validate     # Validate migrations
make db-migrate-hash         # Show migration hash

# Database management
make db-reset               # Reset database (destructive)
make db-shell               # Open PostgreSQL shell
make db-backup              # Create database backup
```

## Development Workflow

### Adding New Features

1. **Design**: Plan your schema changes
2. **Update**: Modify `schema.sql` with new tables/columns
3. **Generate**: Create migration using `make db-migrate-plan`
4. **Review**: Examine generated migration file
5. **Test**: Apply migration to test environment
6. **Apply**: Apply to development environment
7. **Commit**: Add migration files to version control

### Best Practices

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

## Troubleshooting

### Initial Setup Issues

**pgvector Extension Missing**
```bash
# Error: pq: type "public.vector" does not exist
# Solution: Enable pgvector extension
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

**Atlas Schema Revisions Conflict**
```bash
# Error: connected database is not clean: found schema "atlas_schema_revisions"
# Solution: Clean Atlas state before generating initial migration
docker exec dana-local-dev-postgres-1 psql -U dana_user -d dana -c "DROP SCHEMA IF EXISTS atlas_schema_revisions CASCADE;"
```

**Dev Database Configuration**
```bash
# Error: required flag(s) "dev-url" not set
# Solution: Always provide dev-url when generating migrations
atlas migrate diff initial --env local --dev-url "postgresql://dana_user:dana_password@localhost:5432/dana?sslmode=disable"
```

**Atlas CLI Not Found**
```bash
# Error: command not found: atlas
# Solution: Install Atlas CLI
brew install ariga/tap/atlas  # macOS
# OR
curl -sSf https://atlasgo.sh | sh  # Linux/Unix
```

### Common Runtime Issues

**Migration Failed**
```bash
# Check migration status
atlas migrate status --env docker

# Review migration logs
docker-compose logs dana-db-migrate
```

**Schema Drift**
```bash
# Compare current schema with expected
atlas schema diff --env docker

# Reset to known state (development only)
make db-reset
```

**Connection Issues**
```bash
# Test database connectivity
pg_isready -h localhost -p 5432 -U dana_user

# Check Docker network
docker-compose ps postgres
```

### Getting Help

- [Atlas Documentation](https://atlasgo.io/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- DANA Development Team

## Security Considerations

- **Credentials**: Never commit database credentials to version control
- **Encryption**: Use SSL/TLS for database connections in production
- **Access Control**: Limit database access to authorized personnel only
- **Audit**: Monitor and log all schema changes
- **Backup**: Maintain regular backups before schema changes