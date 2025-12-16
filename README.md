# DANA Database Management

Centralized database schema and migration management for the DANA platform using [Atlas](https://atlasgo.io/).

## Overview

This repository manages the core `dana` database which contains platform-level data:
- Organizations, Users, API Keys
- Data Integration tables
- Conversations and chat history
- Workflows and executions
- AI Agents management
- Audit logs and access control

## Project Structure

```
dana-db/
├── atlas.hcl              # Atlas configuration (multi-environment)
├── schema.sql             # Master database schema
├── migrations/            # Migration files
│   └── *.sql              # Timestamped migration files
├── .github/
│   └── workflows/
│       └── migrate.yml    # CI/CD workflow for dev environment
├── scripts/               # Helper scripts
└── docs/                  # Detailed documentation
```

## Quick Start

### Prerequisites

1. **Atlas CLI** installed:
   ```bash
   # macOS
   brew install ariga/tap/atlas

   # Or universal installer
   curl -sSf https://atlasgo.sh | sh

   # Verify installation
   atlas version
   ```

2. **PostgreSQL** running locally (for local development)

---

## Local Development

### One-Command Setup

For new users, create the entire database from scratch:

```bash
# From project root directory
make db-migrate
```

This will:
1. Start PostgreSQL container with pgvector extension
2. Auto-create all required extensions (uuid-ossp, pgcrypto, vector, pg_trgm, btree_gin)
3. Apply all migrations
4. Verify database health and connectivity

### Development Workflow

```bash
# Start development environment
make dev-data                  # Starts postgres + redis + data-integration-engine

# Check migration status
make db-migrate-status          # Shows current version and pending migrations

# Apply migrations
make db-migrate

# Generate new migration from schema changes
make db-migrate-plan
```

### Creating New Migrations

1. **Update the schema**: Modify `schema.sql` with your changes
2. **Generate migration**:
   ```bash
   atlas migrate diff <migration_name> --env local
   ```
3. **Review the generated SQL** in `migrations/`
4. **Apply locally**:
   ```bash
   atlas migrate apply --env local
   ```

---

## Dev Environment (AWS Aurora)

### Architecture

The dev environment runs on AWS Aurora PostgreSQL in a private VPC. Migrations are applied via GitHub Actions using SSM port forwarding through a fck-nat instance.

```
GitHub Actions Runner
    ↓ AWS SSM Port Forwarding
fck-nat Instance (public subnet)
    ↓ Private network
Aurora PostgreSQL (private data subnet)
```

### Automatic CI/CD Migrations

Migrations are **automatically applied** when you push to the `dev` branch:

1. **Push migration files** to the `dev` branch
2. **GitHub Actions** automatically:
   - Detects changes in `migrations/`, `schema.sql`, or `atlas.hcl`
   - Creates SSM tunnel to Aurora through fck-nat
   - Applies pending migrations
3. **Monitor progress** at: https://github.com/trinio-ai/dana-db/actions

### Workflow Triggers

| Trigger | Action |
|---------|--------|
| Push to `dev` (migrations changed) | Plan + Apply migrations |
| Pull request to `dev` | Plan only (no apply) |
| Manual dispatch | Plan + optionally Apply |

### Adding a New Migration

```bash
# 1. Make schema changes
vim schema.sql

# 2. Generate migration locally
atlas migrate diff add_new_feature --env local

# 3. Review the generated migration
cat migrations/<timestamp>_add_new_feature.sql

# 4. Test locally
atlas migrate apply --env local

# 5. Commit and push to dev
git add migrations/
git commit -m "Add new feature migration"
git push origin dev

# 6. Monitor the workflow
gh run watch
```

### Manual Migration (if needed)

If you need to run migrations manually:

```bash
# 1. Connect to Aurora via SSM (requires AWS CLI configured)
aws ssm start-session \
  --target <fck-nat-instance-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<aurora-endpoint>"],"portNumber":["5432"],"localPortNumber":["15432"]}'

# 2. In another terminal, run Atlas
DATABASE_URL="postgresql://user:pass@localhost:15432/dana_db?sslmode=require" \
  atlas migrate apply --env production
```

### Database Credentials

Database credentials are stored in AWS Secrets Manager:
- **Path**: `dana/dev/database/dana`
- **Format**: JSON with `host`, `port`, `dbname`, `username`, `password`

---

## Atlas Environments

| Environment | Use Case | Database URL |
|-------------|----------|--------------|
| `local` | Local development | `localhost:5432` |
| `docker` | Docker Compose | `postgres:5432` |
| `production` | AWS Aurora (via CI/CD) | Dynamic from env var |

### atlas.hcl Configuration

```hcl
env "local" {
  src = "file://schema.sql"
  url = "postgresql://user:pass@localhost:5432/dana_db"
  migration {
    dir = "file://migrations"
  }
}

env "production" {
  url = getenv("DATABASE_URL")
  migration {
    dir = "file://migrations"
  }
  diff {
    skip {
      drop_table = true  # Safety: prevent accidental table drops
    }
  }
}
```

---

## Common Commands

```bash
# Database setup and migration
make db-migrate              # Apply migrations
make db-migrate-status       # Check migration status
make db-migrate-plan         # Generate new migration
make db-migrate-validate     # Validate migrations

# Database management
make db-reset               # Reset database (destructive)
make db-shell               # Open PostgreSQL shell
make db-backup              # Create database backup

# Atlas CLI directly
atlas migrate status --env local
atlas migrate apply --env local
atlas migrate diff <name> --env local
```

---

## Troubleshooting

### Migration failed in CI/CD

1. Check the workflow logs: https://github.com/trinio-ai/dana-db/actions
2. Look for specific error messages in the "Apply migration" step
3. Common issues:
   - **SSM tunnel timeout**: Retry the workflow
   - **Schema conflict**: Check if manual changes were made to the database
   - **Invalid SQL**: Review the migration file locally

### Can't connect to Aurora locally

```bash
# Verify SSM plugin is installed
session-manager-plugin --version

# Check AWS credentials
aws sts get-caller-identity

# Verify fck-nat instance is running
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=dana-dev-fck-nat-1" \
  --query 'Reservations[0].Instances[0].State.Name'
```

### Schema drift detected

```bash
# Compare current database to schema definition
atlas schema diff \
  --from "file://schema.sql" \
  --to "postgresql://user:pass@localhost:5432/dana_db"

# Generate reconciliation migration
atlas migrate diff reconcile_schema --env local
```

### Reset migration state (dev only)

```bash
# If you need to reset the migration tracking table
# WARNING: This does not undo schema changes
psql -h localhost -p 15432 -U postgres -d dana_db -c "
  DELETE FROM atlas_schema_revisions;
"
```

---

## Best Practices

1. **Always test locally first** before pushing to dev
2. **Review generated migrations** - Atlas generates SQL, but you should verify it
3. **Use descriptive migration names** - `add_user_preferences` not `changes`
4. **Never manually edit applied migrations** - create new ones instead
5. **Back up before major changes** in production
6. **Keep migrations small and focused** - one logical change per migration

---

## Security

- Never commit database credentials
- Use AWS Secrets Manager for credentials
- Use SSL/TLS for all database connections
- Migrations are applied via SSM (no direct internet access to database)

---

## References

- [Atlas Documentation](https://atlasgo.io/docs)
- [Atlas PostgreSQL Guide](https://atlasgo.io/guides/postgres)
- [AWS SSM Port Forwarding](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html)
