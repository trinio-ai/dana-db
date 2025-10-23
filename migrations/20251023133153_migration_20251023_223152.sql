-- Create "document_embeddings" table
CREATE TABLE "public"."document_embeddings" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "document_type" character varying(50) NOT NULL,
  "document_id" uuid NOT NULL,
  "chunk_index" integer NULL DEFAULT 0,
  "content" text NOT NULL,
  "metadata" jsonb NULL DEFAULT '{}',
  "embedding" public.vector(1536) NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id")
);
-- Create index "idx_embeddings_org" to table: "document_embeddings"
CREATE INDEX "idx_embeddings_org" ON "public"."document_embeddings" ("organization_id");
-- Create index "idx_embeddings_type" to table: "document_embeddings"
CREATE INDEX "idx_embeddings_type" ON "public"."document_embeddings" ("document_type");
-- Create index "idx_embeddings_vector" to table: "document_embeddings"
CREATE INDEX "idx_embeddings_vector" ON "public"."document_embeddings" USING hnsw ("embedding" vector_cosine_ops);
-- Create "system_metrics" table
CREATE TABLE "public"."system_metrics" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "metric_name" character varying(100) NOT NULL,
  "metric_value" double precision NOT NULL,
  "tags" jsonb NULL DEFAULT '{}',
  "timestamp" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id")
);
-- Create index "idx_metrics_name_time" to table: "system_metrics"
CREATE INDEX "idx_metrics_name_time" ON "public"."system_metrics" ("metric_name", "timestamp" DESC);
-- Create "organizations" table
CREATE TABLE "public"."organizations" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "name" character varying(255) NOT NULL,
  "slug" character varying(100) NOT NULL,
  "plan_type" character varying(50) NOT NULL DEFAULT 'starter',
  "status" character varying(20) NOT NULL DEFAULT 'active',
  "settings" jsonb NULL DEFAULT '{}',
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "organizations_slug_key" UNIQUE ("slug")
);
-- Create index "idx_org_slug" to table: "organizations"
CREATE INDEX "idx_org_slug" ON "public"."organizations" ("slug");
-- Create index "idx_org_status" to table: "organizations"
CREATE INDEX "idx_org_status" ON "public"."organizations" ("status");
-- Create "users" table
CREATE TABLE "public"."users" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "email" character varying(255) NOT NULL,
  "password_hash" character varying(255) NULL,
  "full_name" character varying(255) NOT NULL,
  "role" character varying(50) NOT NULL DEFAULT 'member',
  "is_active" boolean NOT NULL DEFAULT true,
  "permissions" jsonb NULL DEFAULT '{}',
  "preferences" jsonb NULL DEFAULT '{}',
  "last_login" timestamptz NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "users_email_key" UNIQUE ("email"),
  CONSTRAINT "users_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_users_email" to table: "users"
CREATE INDEX "idx_users_email" ON "public"."users" ("email");
-- Create index "idx_users_org" to table: "users"
CREATE INDEX "idx_users_org" ON "public"."users" ("organization_id");
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
  CONSTRAINT "ai_agents_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "ai_agents_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_agents_org" to table: "ai_agents"
CREATE INDEX "idx_agents_org" ON "public"."ai_agents" ("organization_id");
-- Create index "idx_agents_status" to table: "ai_agents"
CREATE INDEX "idx_agents_status" ON "public"."ai_agents" ("status");
-- Create index "idx_agents_type" to table: "ai_agents"
CREATE INDEX "idx_agents_type" ON "public"."ai_agents" ("agent_type");
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
  CONSTRAINT "agent_activities_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."ai_agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_activities_agent" to table: "agent_activities"
CREATE INDEX "idx_activities_agent" ON "public"."agent_activities" ("agent_id", "created_at" DESC);
-- Create index "idx_activities_status" to table: "agent_activities"
CREATE INDEX "idx_activities_status" ON "public"."agent_activities" ("status");
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
  CONSTRAINT "api_keys_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "api_keys_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_apikeys_hash" to table: "api_keys"
CREATE INDEX "idx_apikeys_hash" ON "public"."api_keys" ("key_hash");
-- Create index "idx_apikeys_org" to table: "api_keys"
CREATE INDEX "idx_apikeys_org" ON "public"."api_keys" ("organization_id");
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
  CONSTRAINT "audit_logs_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_audit_logs_event_type" to table: "audit_logs"
CREATE INDEX "idx_audit_logs_event_type" ON "public"."audit_logs" ("event_type");
-- Create index "idx_audit_logs_org_date" to table: "audit_logs"
CREATE INDEX "idx_audit_logs_org_date" ON "public"."audit_logs" ("organization_id", "created_at" DESC);
-- Create index "idx_audit_logs_user" to table: "audit_logs"
CREATE INDEX "idx_audit_logs_user" ON "public"."audit_logs" ("user_id");
-- Create "conversations" table
CREATE TABLE "public"."conversations" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "conversation_type" character varying(20) NOT NULL DEFAULT 'client',
  "title" character varying(255) NULL,
  "context" jsonb NULL DEFAULT '{}',
  "status" character varying(20) NULL DEFAULT 'active',
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "conversations_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "conversations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_conversations_org" to table: "conversations"
CREATE INDEX "idx_conversations_org" ON "public"."conversations" ("organization_id");
-- Create index "idx_conversations_type" to table: "conversations"
CREATE INDEX "idx_conversations_type" ON "public"."conversations" ("conversation_type");
-- Create index "idx_conversations_user" to table: "conversations"
CREATE INDEX "idx_conversations_user" ON "public"."conversations" ("user_id");
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
  CONSTRAINT "chat_messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "chat_messages_parent_message_id_fkey" FOREIGN KEY ("parent_message_id") REFERENCES "public"."chat_messages" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "chat_messages_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_messages_conversation" to table: "chat_messages"
CREATE INDEX "idx_messages_conversation" ON "public"."chat_messages" ("conversation_id", "created_at");
-- Create index "idx_messages_user" to table: "chat_messages"
CREATE INDEX "idx_messages_user" ON "public"."chat_messages" ("user_id");
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
  CONSTRAINT "data_sources_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "data_sources_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_datasources_org" to table: "data_sources"
CREATE INDEX "idx_datasources_org" ON "public"."data_sources" ("organization_id");
-- Create index "idx_datasources_type" to table: "data_sources"
CREATE INDEX "idx_datasources_type" ON "public"."data_sources" ("type");
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
  CONSTRAINT "data_access_logs_data_source_id_fkey" FOREIGN KEY ("data_source_id") REFERENCES "public"."data_sources" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "data_access_logs_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "data_access_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_access_logs_datasource" to table: "data_access_logs"
CREATE INDEX "idx_access_logs_datasource" ON "public"."data_access_logs" ("data_source_id");
-- Create index "idx_access_logs_org_date" to table: "data_access_logs"
CREATE INDEX "idx_access_logs_org_date" ON "public"."data_access_logs" ("organization_id", "created_at" DESC);
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
  CONSTRAINT "data_schemas_data_source_id_fkey" FOREIGN KEY ("data_source_id") REFERENCES "public"."data_sources" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_schemas_datasource" to table: "data_schemas"
CREATE INDEX "idx_schemas_datasource" ON "public"."data_schemas" ("data_source_id");
-- Create index "idx_schemas_table" to table: "data_schemas"
CREATE INDEX "idx_schemas_table" ON "public"."data_schemas" ("table_name");
-- Create "message_feedback" table
CREATE TABLE "public"."message_feedback" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "message_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "feedback_type" character varying(20) NOT NULL,
  "comment" text NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "message_feedback_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "public"."chat_messages" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "message_feedback_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_feedback_message" to table: "message_feedback"
CREATE INDEX "idx_feedback_message" ON "public"."message_feedback" ("message_id");
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
  CONSTRAINT "performance_baselines_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_baselines_org" to table: "performance_baselines"
CREATE INDEX "idx_baselines_org" ON "public"."performance_baselines" ("organization_id");
-- Create "workflows" table
CREATE TABLE "public"."workflows" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "name" character varying(255) NOT NULL,
  "description" text NULL,
  "created_by" uuid NULL,
  "conversation_id" uuid NULL,
  "status" character varying(20) NULL DEFAULT 'draft',
  "workflow_category" character varying(50) NULL,
  "timeout_seconds" integer NULL DEFAULT 300,
  "max_parallel_tasks" integer NULL DEFAULT 5,
  "dag_visualization" jsonb NULL,
  "version" integer NULL DEFAULT 1,
  "parent_workflow_id" uuid NULL,
  "is_latest_version" boolean NULL DEFAULT true,
  "avg_execution_time_ms" integer NULL DEFAULT 0,
  "total_executions" integer NULL DEFAULT 0,
  "success_rate" numeric(5,2) NULL DEFAULT 0.00,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "workflows_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "workflows_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "workflows_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "workflows_parent_workflow_id_fkey" FOREIGN KEY ("parent_workflow_id") REFERENCES "public"."workflows" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_workflows_category" to table: "workflows"
CREATE INDEX "idx_workflows_category" ON "public"."workflows" ("workflow_category");
-- Create index "idx_workflows_org" to table: "workflows"
CREATE INDEX "idx_workflows_org" ON "public"."workflows" ("organization_id");
-- Create index "idx_workflows_user" to table: "workflows"
CREATE INDEX "idx_workflows_user" ON "public"."workflows" ("created_by", "status");
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
  CONSTRAINT "scheduled_tasks_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."ai_agents" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "scheduled_tasks_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "scheduled_tasks_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "scheduled_tasks_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "public"."workflows" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_scheduled_tasks_next_run" to table: "scheduled_tasks"
CREATE INDEX "idx_scheduled_tasks_next_run" ON "public"."scheduled_tasks" ("next_run");
-- Create index "idx_scheduled_tasks_org" to table: "scheduled_tasks"
CREATE INDEX "idx_scheduled_tasks_org" ON "public"."scheduled_tasks" ("organization_id");
-- Create index "idx_scheduled_tasks_status" to table: "scheduled_tasks"
CREATE INDEX "idx_scheduled_tasks_status" ON "public"."scheduled_tasks" ("status");
-- Create "workflow_executions" table
CREATE TABLE "public"."workflow_executions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "workflow_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "conversation_id" uuid NULL,
  "status" character varying(20) NULL DEFAULT 'pending',
  "input_parameters" jsonb NULL,
  "result_data" jsonb NULL,
  "execution_graph" jsonb NULL,
  "current_tasks" jsonb NULL DEFAULT '[]',
  "error_message" text NULL,
  "error_details" jsonb NULL,
  "retry_count" integer NULL DEFAULT 0,
  "max_retries" integer NULL DEFAULT 3,
  "execution_time_ms" integer NULL,
  "queue_time_ms" integer NULL,
  "worker_id" character varying(255) NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "workflow_executions_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "workflow_executions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "workflow_executions_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "public"."workflows" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_workflow_executions_status" to table: "workflow_executions"
CREATE INDEX "idx_workflow_executions_status" ON "public"."workflow_executions" ("status");
-- Create index "idx_workflow_executions_user" to table: "workflow_executions"
CREATE INDEX "idx_workflow_executions_user" ON "public"."workflow_executions" ("user_id", "status");
-- Create index "idx_workflow_executions_workflow" to table: "workflow_executions"
CREATE INDEX "idx_workflow_executions_workflow" ON "public"."workflow_executions" ("workflow_id", "created_at" DESC);
-- Create "tasks" table
CREATE TABLE "public"."tasks" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "name" character varying(255) NOT NULL,
  "description" text NULL,
  "created_by" uuid NULL,
  "conversation_id" uuid NULL,
  "task_type" character varying(20) NOT NULL,
  "task_category" character varying(20) NOT NULL DEFAULT 'custom',
  "status" character varying(20) NULL DEFAULT 'draft',
  "execution_mode" character varying(20) NULL DEFAULT 'synchronous',
  "timeout_seconds" integer NULL DEFAULT 30,
  "html_component" text NOT NULL,
  "validation_schema" jsonb NOT NULL,
  "data_fetch_code" text NULL,
  "data_commit_code" text NULL,
  "data_source_id" uuid NULL,
  "input_schema" jsonb NULL DEFAULT '{}',
  "output_schema" jsonb NULL DEFAULT '{}',
  "s3_bucket" character varying(255) NULL,
  "s3_key" character varying(500) NULL,
  "s3_version_id" character varying(255) NULL,
  "code_hash" character varying(64) NULL,
  "erp_core_endpoint" character varying(255) NULL,
  "deployment_status" character varying(20) NULL DEFAULT 'pending',
  "deployed_version" character varying(50) NULL,
  "version" integer NULL DEFAULT 1,
  "parent_task_id" uuid NULL,
  "is_latest_version" boolean NULL DEFAULT true,
  "avg_execution_time_ms" integer NULL DEFAULT 0,
  "total_executions" integer NULL DEFAULT 0,
  "success_rate" numeric(5,2) NULL DEFAULT 0.00,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "tasks_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "tasks_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "tasks_data_source_id_fkey" FOREIGN KEY ("data_source_id") REFERENCES "public"."data_sources" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "tasks_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "tasks_parent_task_id_fkey" FOREIGN KEY ("parent_task_id") REFERENCES "public"."tasks" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "check_storage_consistency" CHECK ((((task_category)::text = 'core'::text) AND (s3_bucket IS NOT NULL) AND (s3_key IS NOT NULL)) OR (((task_category)::text = 'custom'::text) AND (s3_bucket IS NOT NULL) AND (s3_key IS NOT NULL)))
);
-- Create index "idx_tasks_category" to table: "tasks"
CREATE INDEX "idx_tasks_category" ON "public"."tasks" ("task_category");
-- Create index "idx_tasks_org_type" to table: "tasks"
CREATE INDEX "idx_tasks_org_type" ON "public"."tasks" ("organization_id", "task_type");
-- Create index "idx_tasks_status" to table: "tasks"
CREATE INDEX "idx_tasks_status" ON "public"."tasks" ("status") WHERE ((status)::text = 'active'::text);
-- Create "task_executions" table
CREATE TABLE "public"."task_executions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "task_id" uuid NOT NULL,
  "workflow_execution_id" uuid NULL,
  "user_id" uuid NOT NULL,
  "status" character varying(20) NULL DEFAULT 'pending',
  "input_parameters" jsonb NULL,
  "result_data" jsonb NULL,
  "error_message" text NULL,
  "error_details" jsonb NULL,
  "retry_count" integer NULL DEFAULT 0,
  "execution_time_ms" integer NULL,
  "queue_time_ms" integer NULL,
  "erp_core_instance" character varying(255) NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "fk_task_exec_workflow" FOREIGN KEY ("workflow_execution_id") REFERENCES "public"."workflow_executions" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "task_executions_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "task_executions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_task_executions_status" to table: "task_executions"
CREATE INDEX "idx_task_executions_status" ON "public"."task_executions" ("status");
-- Create index "idx_task_executions_task" to table: "task_executions"
CREATE INDEX "idx_task_executions_task" ON "public"."task_executions" ("task_id", "created_at" DESC);
-- Create index "idx_task_executions_user" to table: "task_executions"
CREATE INDEX "idx_task_executions_user" ON "public"."task_executions" ("user_id");
-- Create index "idx_task_executions_workflow" to table: "task_executions"
CREATE INDEX "idx_task_executions_workflow" ON "public"."task_executions" ("workflow_execution_id");
-- Create "teams" table
CREATE TABLE "public"."teams" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "name" character varying(255) NOT NULL,
  "description" text NULL,
  "created_by" uuid NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "teams_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "teams_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_teams_org" to table: "teams"
CREATE INDEX "idx_teams_org" ON "public"."teams" ("organization_id");
-- Create "task_permissions" table
CREATE TABLE "public"."task_permissions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "task_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "can_view" boolean NULL DEFAULT true,
  "can_edit" boolean NULL DEFAULT false,
  "can_execute" boolean NULL DEFAULT false,
  "can_deploy" boolean NULL DEFAULT false,
  "granted_by" uuid NULL,
  "team_id" uuid NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "task_permissions_task_id_user_id_key" UNIQUE ("task_id", "user_id"),
  CONSTRAINT "task_permissions_granted_by_fkey" FOREIGN KEY ("granted_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "task_permissions_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "task_permissions_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "task_permissions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_task_permissions_task" to table: "task_permissions"
CREATE INDEX "idx_task_permissions_task" ON "public"."task_permissions" ("task_id");
-- Create index "idx_task_permissions_team" to table: "task_permissions"
CREATE INDEX "idx_task_permissions_team" ON "public"."task_permissions" ("team_id");
-- Create index "idx_task_permissions_user" to table: "task_permissions"
CREATE INDEX "idx_task_permissions_user" ON "public"."task_permissions" ("user_id");
-- Create "team_members" table
CREATE TABLE "public"."team_members" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "team_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "role" character varying(50) NULL DEFAULT 'member',
  "added_by" uuid NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "team_members_team_id_user_id_key" UNIQUE ("team_id", "user_id"),
  CONSTRAINT "team_members_added_by_fkey" FOREIGN KEY ("added_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "team_members_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "team_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_team_members_team" to table: "team_members"
CREATE INDEX "idx_team_members_team" ON "public"."team_members" ("team_id");
-- Create index "idx_team_members_user" to table: "team_members"
CREATE INDEX "idx_team_members_user" ON "public"."team_members" ("user_id");
-- Create "user_sessions" table
CREATE TABLE "public"."user_sessions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_id" uuid NOT NULL,
  "session_token" character varying(255) NOT NULL,
  "expires_at" timestamptz NOT NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "user_sessions_session_token_key" UNIQUE ("session_token"),
  CONSTRAINT "user_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_sessions_token" to table: "user_sessions"
CREATE INDEX "idx_sessions_token" ON "public"."user_sessions" ("session_token");
-- Create index "idx_sessions_user" to table: "user_sessions"
CREATE INDEX "idx_sessions_user" ON "public"."user_sessions" ("user_id");
-- Create "workflow_permissions" table
CREATE TABLE "public"."workflow_permissions" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "workflow_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "permission_level" character varying(20) NOT NULL,
  "granted_by" uuid NULL,
  "team_id" uuid NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "workflow_permissions_workflow_id_user_id_key" UNIQUE ("workflow_id", "user_id"),
  CONSTRAINT "workflow_permissions_granted_by_fkey" FOREIGN KEY ("granted_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "workflow_permissions_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "workflow_permissions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "workflow_permissions_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "public"."workflows" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_workflow_permissions_team" to table: "workflow_permissions"
CREATE INDEX "idx_workflow_permissions_team" ON "public"."workflow_permissions" ("team_id");
-- Create index "idx_workflow_permissions_user" to table: "workflow_permissions"
CREATE INDEX "idx_workflow_permissions_user" ON "public"."workflow_permissions" ("user_id");
-- Create index "idx_workflow_permissions_workflow" to table: "workflow_permissions"
CREATE INDEX "idx_workflow_permissions_workflow" ON "public"."workflow_permissions" ("workflow_id");
-- Create "workflow_task_edges" table
CREATE TABLE "public"."workflow_task_edges" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "workflow_id" uuid NOT NULL,
  "source_task_id" uuid NOT NULL,
  "target_task_id" uuid NOT NULL,
  "edge_type" character varying(20) NULL DEFAULT 'sequential',
  "condition_expression" text NULL,
  "data_mapping" jsonb NULL,
  "execution_order" integer NULL DEFAULT 0,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "workflow_task_edges_workflow_id_source_task_id_target_task__key" UNIQUE ("workflow_id", "source_task_id", "target_task_id"),
  CONSTRAINT "workflow_task_edges_source_task_id_fkey" FOREIGN KEY ("source_task_id") REFERENCES "public"."tasks" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "workflow_task_edges_target_task_id_fkey" FOREIGN KEY ("target_task_id") REFERENCES "public"."tasks" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "workflow_task_edges_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "public"."workflows" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_workflow_edges_source" to table: "workflow_task_edges"
CREATE INDEX "idx_workflow_edges_source" ON "public"."workflow_task_edges" ("source_task_id");
-- Create index "idx_workflow_edges_target" to table: "workflow_task_edges"
CREATE INDEX "idx_workflow_edges_target" ON "public"."workflow_task_edges" ("target_task_id");
-- Create index "idx_workflow_edges_workflow" to table: "workflow_task_edges"
CREATE INDEX "idx_workflow_edges_workflow" ON "public"."workflow_task_edges" ("workflow_id");
