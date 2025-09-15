# Atlas migration container
FROM arigaio/atlas:latest

# Set working directory
WORKDIR /migrations

# Copy schema and migration files
COPY schema.sql .
COPY atlas.hcl .
COPY migrations/ ./migrations/

# Default command (can be overridden)
CMD ["migrate", "apply", "--env", "docker"]