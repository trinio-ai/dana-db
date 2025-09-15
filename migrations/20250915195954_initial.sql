-- Create "organizations" table
CREATE TABLE "public"."organizations" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "name" character varying(255) NOT NULL,
  "slug" character varying(100) NOT NULL,
  "plan_type" character varying(50) NOT NULL DEFAULT 'starter',
  "settings" jsonb NULL DEFAULT '{}',
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "organizations_slug_key" UNIQUE ("slug")
);
-- Create index "idx_organizations_slug" to table: "organizations"
CREATE INDEX "idx_organizations_slug" ON "public"."organizations" ("slug");
-- Create "system_metrics" table
CREATE TABLE "public"."system_metrics" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "metric_name" character varying(100) NOT NULL,
  "metric_value" double precision NOT NULL,
  "tags" jsonb NULL DEFAULT '{}',
  "timestamp" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id")
);
-- Create index "idx_system_metrics_name_timestamp" to table: "system_metrics"
CREATE INDEX "idx_system_metrics_name_timestamp" ON "public"."system_metrics" ("metric_name", "timestamp");
-- Create "users" table
CREATE TABLE "public"."users" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "email" character varying(255) NOT NULL,
  "full_name" character varying(255) NOT NULL,
  "role" character varying(50) NOT NULL DEFAULT 'member',
  "permissions" jsonb NULL DEFAULT '{}',
  "preferences" jsonb NULL DEFAULT '{}',
  "last_login" timestamptz NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "users_email_key" UNIQUE ("email"),
  CONSTRAINT "users_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_users_email" to table: "users"
CREATE INDEX "idx_users_email" ON "public"."users" ("email");
-- Create index "idx_users_organization_id" to table: "users"
CREATE INDEX "idx_users_organization_id" ON "public"."users" ("organization_id");
-- Create "ai_agents" table
CREATE TABLE "public"."ai_agents" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "name" character varying(255) NOT NULL,
  "description" text NULL,
  "agent_type" character varying(50) NOT NULL,
  "config" jsonb NOT NULL,
  "capabilities" text[] NULL DEFAULT '{}',
  "data_access_permissions" jsonb NULL DEFAULT '{}',
  "status" character varying(20) NULL DEFAULT 'inactive',
  "last_activity" timestamptz NULL,
  "created_by" uuid NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "ai_agents_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT "ai_agents_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_ai_agents_organization_id" to table: "ai_agents"
CREATE INDEX "idx_ai_agents_organization_id" ON "public"."ai_agents" ("organization_id");
-- Create index "idx_ai_agents_type" to table: "ai_agents"
CREATE INDEX "idx_ai_agents_type" ON "public"."ai_agents" ("agent_type");
-- Create "agent_activities" table
CREATE TABLE "public"."agent_activities" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "agent_id" uuid NOT NULL,
  "activity_type" character varying(50) NOT NULL,
  "input_data" jsonb NULL,
  "output_data" jsonb NULL,
  "status" character varying(20) NULL DEFAULT 'pending',
  "execution_time_ms" integer NULL,
  "error_message" text NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "agent_activities_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."ai_agents" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_agent_activities_agent_id" to table: "agent_activities"
CREATE INDEX "idx_agent_activities_agent_id" ON "public"."agent_activities" ("agent_id");
-- Create "api_keys" table
CREATE TABLE "public"."api_keys" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "user_id" uuid NULL,
  "name" character varying(255) NOT NULL,
  "key_hash" character varying(255) NOT NULL,
  "permissions" jsonb NULL DEFAULT '{}',
  "expires_at" timestamptz NULL,
  "last_used" timestamptz NULL,
  "status" character varying(20) NULL DEFAULT 'active',
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "api_keys_key_hash_key" UNIQUE ("key_hash"),
  CONSTRAINT "api_keys_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "api_keys_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE SET NULL
);
-- Create index "idx_api_keys_key_hash" to table: "api_keys"
CREATE INDEX "idx_api_keys_key_hash" ON "public"."api_keys" ("key_hash");
-- Create index "idx_api_keys_organization_id" to table: "api_keys"
CREATE INDEX "idx_api_keys_organization_id" ON "public"."api_keys" ("organization_id");
-- Create "audit_logs" table
CREATE TABLE "public"."audit_logs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "user_id" uuid NULL,
  "event_type" character varying(50) NOT NULL,
  "resource_type" character varying(50) NULL,
  "resource_id" uuid NULL,
  "event_data" jsonb NULL DEFAULT '{}',
  "ip_address" inet NULL,
  "user_agent" text NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "audit_logs_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE SET NULL
);
-- Create index "idx_audit_logs_created_at" to table: "audit_logs"
CREATE INDEX "idx_audit_logs_created_at" ON "public"."audit_logs" ("created_at");
-- Create index "idx_audit_logs_organization_id" to table: "audit_logs"
CREATE INDEX "idx_audit_logs_organization_id" ON "public"."audit_logs" ("organization_id");
-- Create "conversations" table
CREATE TABLE "public"."conversations" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_id" uuid NOT NULL,
  "title" character varying(255) NULL,
  "context" jsonb NULL DEFAULT '{}',
  "status" character varying(20) NULL DEFAULT 'active',
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "conversations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_conversations_status" to table: "conversations"
CREATE INDEX "idx_conversations_status" ON "public"."conversations" ("status");
-- Create index "idx_conversations_user_id" to table: "conversations"
CREATE INDEX "idx_conversations_user_id" ON "public"."conversations" ("user_id");
-- Create "chat_messages" table
CREATE TABLE "public"."chat_messages" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "conversation_id" uuid NOT NULL,
  "user_id" uuid NULL,
  "role" character varying(20) NOT NULL,
  "content" text NOT NULL,
  "metadata" jsonb NULL DEFAULT '{}',
  "parent_message_id" uuid NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "chat_messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "chat_messages_parent_message_id_fkey" FOREIGN KEY ("parent_message_id") REFERENCES "public"."chat_messages" ("id") ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT "chat_messages_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE SET NULL
);
-- Create index "idx_chat_messages_conversation_id" to table: "chat_messages"
CREATE INDEX "idx_chat_messages_conversation_id" ON "public"."chat_messages" ("conversation_id");
-- Create "data_sources" table
CREATE TABLE "public"."data_sources" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "name" character varying(255) NOT NULL,
  "type" character varying(50) NOT NULL,
  "connection_config" jsonb NOT NULL,
  "schema_cache" jsonb NULL,
  "health_status" character varying(20) NULL DEFAULT 'unknown',
  "last_health_check" timestamptz NULL,
  "created_by" uuid NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "data_sources_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT "data_sources_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_data_sources_organization_id" to table: "data_sources"
CREATE INDEX "idx_data_sources_organization_id" ON "public"."data_sources" ("organization_id");
-- Create "data_access_logs" table
CREATE TABLE "public"."data_access_logs" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "user_id" uuid NULL,
  "data_source_id" uuid NULL,
  "table_name" character varying(255) NULL,
  "query_hash" character varying(64) NULL,
  "row_count" integer NULL,
  "execution_time_ms" integer NULL,
  "status" character varying(20) NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "data_access_logs_data_source_id_fkey" FOREIGN KEY ("data_source_id") REFERENCES "public"."data_sources" ("id") ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT "data_access_logs_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "data_access_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE SET NULL
);
-- Create index "idx_data_access_logs_created_at" to table: "data_access_logs"
CREATE INDEX "idx_data_access_logs_created_at" ON "public"."data_access_logs" ("created_at");
-- Create index "idx_data_access_logs_organization_id" to table: "data_access_logs"
CREATE INDEX "idx_data_access_logs_organization_id" ON "public"."data_access_logs" ("organization_id");
-- Create "data_schemas" table
CREATE TABLE "public"."data_schemas" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "data_source_id" uuid NOT NULL,
  "schema_name" character varying(255) NULL,
  "table_name" character varying(255) NOT NULL,
  "columns" jsonb NOT NULL,
  "relationships" jsonb NULL DEFAULT '{}',
  "metadata" jsonb NULL DEFAULT '{}',
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "data_schemas_data_source_id_fkey" FOREIGN KEY ("data_source_id") REFERENCES "public"."data_sources" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_data_schemas_data_source_id" to table: "data_schemas"
CREATE INDEX "idx_data_schemas_data_source_id" ON "public"."data_schemas" ("data_source_id");
-- Create "document_embeddings" table
CREATE TABLE "public"."document_embeddings" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "document_type" character varying(50) NOT NULL,
  "document_id" uuid NOT NULL,
  "content" text NOT NULL,
  "metadata" jsonb NULL DEFAULT '{}',
  "embedding" public.vector(1536) NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "document_embeddings_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "document_embeddings_embedding_idx" to table: "document_embeddings"
CREATE INDEX "document_embeddings_embedding_idx" ON "public"."document_embeddings" USING hnsw ("embedding" vector_cosine_ops);
-- Create "message_feedback" table
CREATE TABLE "public"."message_feedback" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "message_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "feedback_type" character varying(20) NOT NULL,
  "comment" text NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "message_feedback_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "public"."chat_messages" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "message_feedback_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_message_feedback_message_id" to table: "message_feedback"
CREATE INDEX "idx_message_feedback_message_id" ON "public"."message_feedback" ("message_id");
-- Create "performance_baselines" table
CREATE TABLE "public"."performance_baselines" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "metric_type" character varying(50) NOT NULL,
  "baseline_value" double precision NOT NULL,
  "threshold_warning" double precision NULL,
  "threshold_critical" double precision NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "performance_baselines_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create "workflows" table
CREATE TABLE "public"."workflows" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "name" character varying(255) NOT NULL,
  "description" text NULL,
  "user_id" character varying(255) NOT NULL,
  "conversation_id" uuid NULL,
  "workflow_type" character varying(50) NOT NULL DEFAULT 'general',
  "status" character varying(20) NULL DEFAULT 'draft',
  "user_prompt" text NOT NULL,
  "database_context" jsonb NULL,
  "input_form" jsonb NULL,
  "operation_code" jsonb NOT NULL,
  "output_template" jsonb NULL,
  "validation_rules" jsonb NULL DEFAULT '[]',
  "tags" text[] NULL DEFAULT '{}',
  "version" integer NULL DEFAULT 1,
  "parent_workflow_id" uuid NULL,
  "is_latest_version" boolean NULL DEFAULT true,
  "avg_execution_time_ms" integer NULL DEFAULT 0,
  "total_executions" integer NULL DEFAULT 0,
  "success_rate" numeric(5,2) NULL DEFAULT 0.00,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "workflows_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations" ("id") ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT "workflows_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "workflows_parent_workflow_id_fkey" FOREIGN KEY ("parent_workflow_id") REFERENCES "public"."workflows" ("id") ON UPDATE NO ACTION ON DELETE SET NULL
);
-- Create index "idx_workflows_conversation_id" to table: "workflows"
CREATE INDEX "idx_workflows_conversation_id" ON "public"."workflows" ("conversation_id");
-- Create index "idx_workflows_organization_id" to table: "workflows"
CREATE INDEX "idx_workflows_organization_id" ON "public"."workflows" ("organization_id");
-- Create index "idx_workflows_status" to table: "workflows"
CREATE INDEX "idx_workflows_status" ON "public"."workflows" ("status");
-- Create "scheduled_tasks" table
CREATE TABLE "public"."scheduled_tasks" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "agent_id" uuid NULL,
  "workflow_id" uuid NULL,
  "name" character varying(255) NOT NULL,
  "schedule_expression" character varying(100) NOT NULL,
  "timezone" character varying(50) NULL DEFAULT 'UTC',
  "task_config" jsonb NOT NULL,
  "status" character varying(20) NULL DEFAULT 'active',
  "last_run" timestamptz NULL,
  "next_run" timestamptz NULL,
  "run_count" integer NULL DEFAULT 0,
  "failure_count" integer NULL DEFAULT 0,
  "created_by" uuid NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "scheduled_tasks_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."ai_agents" ("id") ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT "scheduled_tasks_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT "scheduled_tasks_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "scheduled_tasks_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "public"."workflows" ("id") ON UPDATE NO ACTION ON DELETE SET NULL
);
-- Create index "idx_scheduled_tasks_next_run" to table: "scheduled_tasks"
CREATE INDEX "idx_scheduled_tasks_next_run" ON "public"."scheduled_tasks" ("next_run");
-- Create index "idx_scheduled_tasks_organization_id" to table: "scheduled_tasks"
CREATE INDEX "idx_scheduled_tasks_organization_id" ON "public"."scheduled_tasks" ("organization_id");
-- Create "user_sessions" table
CREATE TABLE "public"."user_sessions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_id" uuid NOT NULL,
  "session_token" character varying(255) NOT NULL,
  "expires_at" timestamptz NOT NULL,
  "metadata" jsonb NULL DEFAULT '{}',
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "user_sessions_session_token_key" UNIQUE ("session_token"),
  CONSTRAINT "user_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_user_sessions_expires" to table: "user_sessions"
CREATE INDEX "idx_user_sessions_expires" ON "public"."user_sessions" ("expires_at");
-- Create index "idx_user_sessions_token" to table: "user_sessions"
CREATE INDEX "idx_user_sessions_token" ON "public"."user_sessions" ("session_token");
-- Create index "idx_user_sessions_user_id" to table: "user_sessions"
CREATE INDEX "idx_user_sessions_user_id" ON "public"."user_sessions" ("user_id");
-- Create "workflow_executions" table
CREATE TABLE "public"."workflow_executions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "workflow_id" uuid NOT NULL,
  "user_id" character varying(255) NOT NULL,
  "conversation_id" uuid NULL,
  "status" character varying(20) NULL DEFAULT 'pending',
  "priority" character varying(10) NULL DEFAULT 'normal',
  "input_parameters" jsonb NULL,
  "result_data" jsonb NULL,
  "error_message" text NULL,
  "error_details" jsonb NULL,
  "retry_count" integer NULL DEFAULT 0,
  "parent_execution_id" uuid NULL,
  "execution_time_ms" integer NULL,
  "queue_time_ms" integer NULL,
  "memory_used_mb" integer NULL,
  "cpu_used_percent" numeric(5,2) NULL,
  "worker_id" character varying(255) NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "workflow_executions_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations" ("id") ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT "workflow_executions_parent_execution_id_fkey" FOREIGN KEY ("parent_execution_id") REFERENCES "public"."workflow_executions" ("id") ON UPDATE NO ACTION ON DELETE SET NULL,
  CONSTRAINT "workflow_executions_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "public"."workflows" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_workflow_executions_created_at" to table: "workflow_executions"
CREATE INDEX "idx_workflow_executions_created_at" ON "public"."workflow_executions" ("created_at");
-- Create index "idx_workflow_executions_status" to table: "workflow_executions"
CREATE INDEX "idx_workflow_executions_status" ON "public"."workflow_executions" ("status");
-- Create index "idx_workflow_executions_workflow_id" to table: "workflow_executions"
CREATE INDEX "idx_workflow_executions_workflow_id" ON "public"."workflow_executions" ("workflow_id");
