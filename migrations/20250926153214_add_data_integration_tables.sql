-- Modify "conversations" table
ALTER TABLE "public"."conversations" DROP COLUMN "is_archived";
-- Modify "chat_messages" table
ALTER TABLE "public"."chat_messages" DROP COLUMN "sender", DROP COLUMN "error", DROP COLUMN "message_order";
-- Modify "workflow_executions" table
ALTER TABLE "public"."workflow_executions" DROP COLUMN "progress", DROP COLUMN "form_data";
-- Create "integration_connections" table
CREATE TABLE "public"."integration_connections" (
  "id" character varying(255) NOT NULL,
  "organization_id" uuid NOT NULL,
  "name" character varying(255) NOT NULL,
  "type" character varying(50) NOT NULL,
  "host" character varying(255) NULL,
  "port" integer NULL,
  "database_name" character varying(255) NULL,
  "status" character varying(20) NULL DEFAULT 'unknown',
  "last_tested" timestamptz NULL,
  "capabilities" text[] NULL,
  "config_encrypted" text NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "integration_connections_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_integration_connections_organization_id" to table: "integration_connections"
CREATE INDEX "idx_integration_connections_organization_id" ON "public"."integration_connections" ("organization_id");
-- Create index "idx_integration_connections_status" to table: "integration_connections"
CREATE INDEX "idx_integration_connections_status" ON "public"."integration_connections" ("status");
-- Create index "idx_integration_connections_type" to table: "integration_connections"
CREATE INDEX "idx_integration_connections_type" ON "public"."integration_connections" ("type");
-- Create "integration_connection_tests" table
CREATE TABLE "public"."integration_connection_tests" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "connection_id" character varying(255) NOT NULL,
  "success" boolean NOT NULL,
  "status" character varying(20) NOT NULL,
  "response_time_ms" bigint NOT NULL,
  "tested_at" timestamptz NOT NULL,
  "server_version" character varying(255) NULL,
  "available_schemas" text[] NULL,
  "connection_pool_status" character varying(50) NULL,
  "error_message" text NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "integration_connection_tests_connection_id_fkey" FOREIGN KEY ("connection_id") REFERENCES "public"."integration_connections" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_integration_connection_tests_connection_id" to table: "integration_connection_tests"
CREATE INDEX "idx_integration_connection_tests_connection_id" ON "public"."integration_connection_tests" ("connection_id");
-- Create index "idx_integration_connection_tests_tested_at" to table: "integration_connection_tests"
CREATE INDEX "idx_integration_connection_tests_tested_at" ON "public"."integration_connection_tests" ("tested_at");
-- Create "integration_database_contexts" table
CREATE TABLE "public"."integration_database_contexts" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "schema_version" character varying(50) NOT NULL,
  "database_name" character varying(255) NULL,
  "schema_name" character varying(255) NULL,
  "context_data" jsonb NOT NULL,
  "last_updated" timestamptz NOT NULL,
  "cache_expires" timestamptz NOT NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "integration_database_contexts_organization_id_database_name_key" UNIQUE ("organization_id", "database_name", "schema_name"),
  CONSTRAINT "integration_database_contexts_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_integration_database_contexts_cache_expires" to table: "integration_database_contexts"
CREATE INDEX "idx_integration_database_contexts_cache_expires" ON "public"."integration_database_contexts" ("cache_expires");
-- Create index "idx_integration_database_contexts_organization_id" to table: "integration_database_contexts"
CREATE INDEX "idx_integration_database_contexts_organization_id" ON "public"."integration_database_contexts" ("organization_id");
-- Modify "users" table
ALTER TABLE "public"."users" DROP COLUMN "username", DROP COLUMN "hashed_password", DROP COLUMN "avatar", DROP COLUMN "is_admin";
-- Create "integration_query_logs" table
CREATE TABLE "public"."integration_query_logs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "connection_id" character varying(255) NULL,
  "query_hash" character varying(64) NOT NULL,
  "query_type" character varying(20) NOT NULL,
  "success" boolean NOT NULL,
  "execution_time_ms" bigint NOT NULL,
  "affected_rows" bigint NULL,
  "result_row_count" bigint NULL,
  "error_message" text NULL,
  "error_code" character varying(50) NULL,
  "user_id" uuid NULL,
  "request_id" character varying(255) NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "integration_query_logs_connection_id_fkey" FOREIGN KEY ("connection_id") REFERENCES "public"."integration_connections" ("id") ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT "integration_query_logs_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "integration_query_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE SET NULL
);
-- Create index "idx_integration_query_logs_connection_id" to table: "integration_query_logs"
CREATE INDEX "idx_integration_query_logs_connection_id" ON "public"."integration_query_logs" ("connection_id");
-- Create index "idx_integration_query_logs_created_at" to table: "integration_query_logs"
CREATE INDEX "idx_integration_query_logs_created_at" ON "public"."integration_query_logs" ("created_at");
-- Create index "idx_integration_query_logs_organization_id" to table: "integration_query_logs"
CREATE INDEX "idx_integration_query_logs_organization_id" ON "public"."integration_query_logs" ("organization_id");
-- Create index "idx_integration_query_logs_query_hash" to table: "integration_query_logs"
CREATE INDEX "idx_integration_query_logs_query_hash" ON "public"."integration_query_logs" ("query_hash");
-- Create "integration_query_metrics" table
CREATE TABLE "public"."integration_query_metrics" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "connection_id" character varying(255) NULL,
  "query_pattern_hash" character varying(64) NOT NULL,
  "avg_execution_time_ms" numeric(10,2) NOT NULL,
  "min_execution_time_ms" bigint NOT NULL,
  "max_execution_time_ms" bigint NOT NULL,
  "execution_count" bigint NOT NULL DEFAULT 1,
  "success_rate" numeric(5,2) NOT NULL DEFAULT 100.00,
  "last_executed" timestamptz NOT NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "integration_query_metrics_organization_id_connection_id_que_key" UNIQUE ("organization_id", "connection_id", "query_pattern_hash"),
  CONSTRAINT "integration_query_metrics_connection_id_fkey" FOREIGN KEY ("connection_id") REFERENCES "public"."integration_connections" ("id") ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT "integration_query_metrics_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_integration_query_metrics_connection_id" to table: "integration_query_metrics"
CREATE INDEX "idx_integration_query_metrics_connection_id" ON "public"."integration_query_metrics" ("connection_id");
-- Create index "idx_integration_query_metrics_last_executed" to table: "integration_query_metrics"
CREATE INDEX "idx_integration_query_metrics_last_executed" ON "public"."integration_query_metrics" ("last_executed");
-- Create index "idx_integration_query_metrics_organization_id" to table: "integration_query_metrics"
CREATE INDEX "idx_integration_query_metrics_organization_id" ON "public"."integration_query_metrics" ("organization_id");
-- Create "integration_schema_cache" table
CREATE TABLE "public"."integration_schema_cache" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "connection_id" character varying(255) NOT NULL,
  "schema_name" character varying(255) NULL,
  "table_name" character varying(255) NOT NULL,
  "columns" jsonb NOT NULL,
  "indexes" jsonb NULL DEFAULT '[]',
  "foreign_keys" jsonb NULL DEFAULT '[]',
  "triggers" jsonb NULL DEFAULT '[]',
  "relationships" jsonb NULL DEFAULT '[]',
  "row_count" bigint NULL,
  "size_mb" numeric(10,2) NULL,
  "last_analyzed" timestamptz NULL,
  "cache_expires" timestamptz NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "integration_schema_cache_connection_id_fkey" FOREIGN KEY ("connection_id") REFERENCES "public"."integration_connections" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "integration_schema_cache_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_integration_schema_cache_connection_id" to table: "integration_schema_cache"
CREATE INDEX "idx_integration_schema_cache_connection_id" ON "public"."integration_schema_cache" ("connection_id");
-- Create index "idx_integration_schema_cache_organization_id" to table: "integration_schema_cache"
CREATE INDEX "idx_integration_schema_cache_organization_id" ON "public"."integration_schema_cache" ("organization_id");
-- Create index "idx_integration_schema_cache_table_name" to table: "integration_schema_cache"
CREATE INDEX "idx_integration_schema_cache_table_name" ON "public"."integration_schema_cache" ("table_name");
-- Modify "workflows" table
ALTER TABLE "public"."workflows" DROP COLUMN "module_id", DROP COLUMN "form_config", DROP COLUMN "category", DROP COLUMN "estimated_duration";
-- Drop "uploaded_files" table
DROP TABLE "public"."uploaded_files";
-- Drop "workflow_modules" table
DROP TABLE "public"."workflow_modules";
