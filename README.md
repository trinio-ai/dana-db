# DANA Database Management

Centralized database schema and migration management for the DANA platform using [Atlas](https://atlasgo.io/).

## ⚡ Quick Start

### One-Command Setup

For new users, create the entire database from scratch:

```bash
# From project root directory
make db-migrate
```

This will:
1. ✅ Start PostgreSQL container with pgvector extension
2. ✅ Auto-create all required extensions (uuid-ossp, pgcrypto, vector, pg_trgm, btree_gin)
3. ✅ Apply all migrations (25+ tables including data integration engine)
4. ✅ Verify database health and connectivity

### Development Workflow

```bash
# Start development environment
make dev-data                  # Starts postgres + redis + data-integration-engine

# Check migration status
make db-migrate-status          # Shows current version and pending migrations

# Start other services
make dev-backend               # Backend API
make dev-frontend              # Next.js frontend
make dev-workflow              # Workflow services
```

## 🏗️ Project Structure

```
dana-db/
├── atlas.hcl              # Atlas configuration (multi-environment)
├── schema.sql             # Master database schema
├── migrations/            # Generated migration files
├── scripts/               # Helper scripts and initialization
├── docs/                  # Detailed documentation
│   ├── schema-overview.md    # Database schema and tables
│   ├── atlas-migrations.md  # Migration system details
│   └── testing-verification.md # Testing procedures
└── Dockerfile             # Atlas container for migrations
```

## 🚀 Key Features

- **🔄 Self-Contained Migrations**: Extensions auto-created in migration files
- **🐳 Docker Integration**: Full containerized migration workflow
- **🏗️ Multi-Environment**: Local, Docker, test, and production configs
- **📊 Vector Support**: pgvector for AI/ML embeddings with HNSW indexes
- **🔧 Make Commands**: Simple `make db-migrate` workflow
- **✅ Fresh Setup**: Complete database creation from scratch

## 📚 Documentation

- **[Schema Overview](docs/schema-overview.md)** - Database tables and relationships
- **[Atlas Migrations](docs/atlas-migrations.md)** - Migration system and workflows
- **[Testing & Verification](docs/testing-verification.md)** - Testing procedures and health checks

## 🔧 Common Commands

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
```

## 🌍 Environments

- **local**: Local development (postgres on localhost)
- **docker**: Docker Compose development (postgres container)
- **test**: Testing environments
- **production**: Production deployments

## 💡 Innovation: Self-Contained Extensions

Our migration files automatically include required PostgreSQL extensions, making them work on any fresh PostgreSQL instance without manual setup:

```sql
-- migrations/20250915195954_initial.sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";
-- Then create tables...
```

This ensures new developers get a working database instantly with `make db-migrate`.

## 🛠️ Development

### Adding New Features

1. **Update**: Modify `schema.sql` with new tables/columns
2. **Generate**: `make db-migrate-plan`
3. **Review**: Check generated migration in `migrations/`
4. **Apply**: `make db-migrate`
5. **Validate**: `make db-migrate-status`

### Best Practices

- Make incremental changes
- Test migrations before applying
- Review migration files
- Document schema changes

## 📋 Database Schema

The database includes:

- **Core Tables**: Organizations, Users, API Keys
- **Data Integration**: 6 tables for universal data access
- **Conversations**: Chat history and messages
- **Workflows**: Definitions and executions
- **AI Agents**: Autonomous agent management
- **Security**: Audit logs and access control

See [Schema Overview](docs/schema-overview.md) for complete details.

## 🚨 Troubleshooting

For detailed troubleshooting steps, see [Testing & Verification](docs/testing-verification.md).

### Quick Fixes

```bash
# Clean environment and restart
docker-compose down --remove-orphans -v
make dev-data

# Check Atlas status
make db-migrate-status

# Validate database health
make db-shell
\dt integration*  # Should show 6 integration tables
\dx              # Should show all extensions
```

## 🔒 Security

- Never commit database credentials
- Use SSL/TLS in production
- Regular backups before changes
- Monitor and audit schema changes

---

For detailed technical documentation, see the [docs/](docs/) directory.