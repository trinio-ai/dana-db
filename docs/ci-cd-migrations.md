# CI/CD Database Migrations

This document describes the automated database migration process using GitHub Actions.

## Overview

Database migrations are automatically applied when changes are pushed to the `dev` branch. The workflow connects to Aurora PostgreSQL in the private VPC via SSM port forwarding through the fck-nat instance.

## Architecture

```
GitHub Actions Runner (internet)
    |
    | AWS SSM Port Forwarding
    v
fck-nat Instance (public subnet, SSM-enabled)
    |
    | Private network
    v
Aurora PostgreSQL (private data subnet)
```

## Workflow Triggers

The migration workflow (`.github/workflows/migrate.yml`) triggers on:

| Event | Paths | Action |
|-------|-------|--------|
| Push to `dev` | `migrations/**`, `schema.sql`, `atlas.hcl` | Lint + Plan + Apply |
| PR to `dev` | `migrations/**`, `schema.sql`, `atlas.hcl` | Lint + Plan only |
| Manual dispatch | Any | Lint + Plan + Apply (with dry_run option) |

## Workflow Stages

### 1. Lint
Validates migration files using Atlas lint:
- Checks for SQL syntax errors
- Validates migration structure
- Ensures backwards compatibility

### 2. Plan
Connects to Aurora via SSM tunnel and checks:
- Current migration status
- Pending migrations to apply
- Outputs whether changes are detected

### 3. Apply
Only runs on push events (not PRs):
- Establishes SSM tunnel to Aurora
- Applies pending migrations
- Verifies successful application

## Required GitHub Secrets

Configure these secrets in your repository settings (Settings > Secrets and variables > Actions):

| Secret | Description | How to Get |
|--------|-------------|------------|
| `AWS_ACCESS_KEY_ID` | IAM user access key | From AWS Secrets Manager: `dana/dev/github-migrations-credentials` |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key | From AWS Secrets Manager: `dana/dev/github-migrations-credentials` |
| `ATLAS_CLOUD_TOKEN` | (Optional) Atlas Cloud token | From [Atlas Cloud](https://atlasgo.cloud) |

### Getting AWS Credentials

```bash
# Get the access key ID
aws secretsmanager get-secret-value \
  --secret-id "dana/dev/github-migrations-credentials" \
  --query 'SecretString' --output text | jq -r '.access_key_id'

# Get the secret access key
aws secretsmanager get-secret-value \
  --secret-id "dana/dev/github-migrations-credentials" \
  --query 'SecretString' --output text | jq -r '.secret_access_key'
```

## Manual Workflow Dispatch

You can manually trigger the workflow from the Actions tab:

1. Go to Actions > Database Migration
2. Click "Run workflow"
3. Optionally enable "Dry run" to plan without applying
4. Click "Run workflow"

## Database Credentials

The workflow retrieves database credentials from AWS Secrets Manager:
- Secret path: `dana/dev/database/dana`
- Contains: host, port, dbname, username, password

## SSM Tunnel Details

The workflow establishes an SSM tunnel through the fck-nat instance:
- Instance tag: `dana-dev-fck-nat`
- Local port: `15432`
- Remote port: `5432` (Aurora)

## Troubleshooting

### Workflow fails to find fck-nat instance
- Ensure the fck-nat instance is running
- Check the instance tag matches `dana-dev-fck-nat`
- Verify IAM permissions include `ec2:DescribeInstances`

### SSM tunnel fails to establish
- Check IAM permissions for SSM
- Verify fck-nat instance has SSM agent running
- Check VPC endpoints for SSM are configured

### Migration fails to apply
- Check Atlas lint output for errors
- Verify database credentials are correct
- Ensure database is accessible through the tunnel

### Viewing Workflow Logs
1. Go to Actions tab
2. Click on the failed workflow run
3. Expand the failed step to see detailed logs

## Local Development

For local development, use the existing environments in `atlas.hcl`:

```bash
# Local development
atlas migrate apply --env local

# Docker development
atlas migrate apply --env docker

# Check status
atlas migrate status --env local
```

## Security Considerations

- IAM user has minimal required permissions
- Database credentials stored in Secrets Manager with KMS encryption
- SSM tunnel encrypted in transit
- No direct internet access to Aurora
- Secrets masked in workflow logs

## Related Documentation

- [Atlas Migrations](atlas-migrations.md) - Migration system details
- [Schema Overview](schema-overview.md) - Database schema documentation
