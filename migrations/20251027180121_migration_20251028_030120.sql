-- Modify "agent_activities" table
ALTER TABLE "public"."agent_activities" ADD COLUMN "updated_at" timestamptz NULL DEFAULT now();
-- Modify "api_keys" table
ALTER TABLE "public"."api_keys" ADD COLUMN "updated_at" timestamptz NULL DEFAULT now();
-- Modify "audit_logs" table
ALTER TABLE "public"."audit_logs" ADD COLUMN "updated_at" timestamptz NULL DEFAULT now();
-- Modify "chat_messages" table
ALTER TABLE "public"."chat_messages" ADD COLUMN "updated_at" timestamptz NULL DEFAULT now();
-- Modify "data_access_logs" table
ALTER TABLE "public"."data_access_logs" ADD COLUMN "updated_at" timestamptz NULL DEFAULT now();
-- Modify "document_embeddings" table
ALTER TABLE "public"."document_embeddings" ADD COLUMN "updated_at" timestamptz NULL DEFAULT now();
-- Modify "message_feedback" table
ALTER TABLE "public"."message_feedback" ADD COLUMN "updated_at" timestamptz NULL DEFAULT now();
-- Modify "performance_baselines" table
ALTER TABLE "public"."performance_baselines" ADD COLUMN "updated_at" timestamptz NULL DEFAULT now();
-- Modify "team_members" table
ALTER TABLE "public"."team_members" ADD COLUMN "updated_at" timestamptz NULL DEFAULT now();
-- Modify "workflow_task_edges" table
ALTER TABLE "public"."workflow_task_edges" ADD COLUMN "updated_at" timestamptz NULL DEFAULT now();
