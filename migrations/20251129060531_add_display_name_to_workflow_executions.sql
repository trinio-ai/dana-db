-- Modify "workflow_executions" table
ALTER TABLE "public"."workflow_executions" ADD COLUMN "display_name" character varying(255) NULL;
