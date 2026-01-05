-- Modify "audit_logs" table
ALTER TABLE "public"."audit_logs" DROP CONSTRAINT "audit_logs_user_id_fkey", DROP COLUMN "event_type", ALTER COLUMN "resource_type" SET NOT NULL, ALTER COLUMN "resource_id" TYPE character varying(255), DROP COLUMN "event_data", ALTER COLUMN "ip_address" TYPE character varying(45), ALTER COLUMN "user_agent" TYPE character varying(500), ADD COLUMN "user_email" character varying(255) NULL, ADD COLUMN "action_type" character varying(50) NOT NULL, ADD COLUMN "resource_name" character varying(255) NULL, ADD COLUMN "before_value" jsonb NULL, ADD COLUMN "after_value" jsonb NULL, ADD COLUMN "extra_data" jsonb NULL DEFAULT '{}', ADD COLUMN "description" text NULL, ADD COLUMN "status" character varying(20) NOT NULL DEFAULT 'success', ADD COLUMN "error_message" text NULL, ADD
CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE SET NULL;
-- Create index "idx_audit_logs_action_type" to table: "audit_logs"
CREATE INDEX "idx_audit_logs_action_type" ON "public"."audit_logs" ("action_type");
-- Create index "idx_audit_logs_resource_id" to table: "audit_logs"
CREATE INDEX "idx_audit_logs_resource_id" ON "public"."audit_logs" ("resource_id");
-- Create index "idx_audit_logs_resource_type" to table: "audit_logs"
CREATE INDEX "idx_audit_logs_resource_type" ON "public"."audit_logs" ("resource_type");
