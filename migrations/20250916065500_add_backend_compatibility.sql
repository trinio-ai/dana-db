-- Add backend compatibility to existing enterprise schema
-- This migration extends existing tables to support dana-backend functionality

-- Add backend-specific columns to existing users table
ALTER TABLE "public"."users"
ADD COLUMN "username" character varying(255) NULL,
ADD COLUMN "hashed_password" character varying(255) NULL,
ADD COLUMN "avatar" character varying(255) NULL,
ADD COLUMN "is_admin" boolean NULL DEFAULT false;

-- Create unique constraint and index for username (for backend compatibility)
CREATE UNIQUE INDEX "users_username_key" ON "public"."users" ("username") WHERE "username" IS NOT NULL;
CREATE INDEX "ix_users_username" ON "public"."users" ("username");

-- Add backend-specific columns to existing chat_messages table
ALTER TABLE "public"."chat_messages"
ADD COLUMN "sender" character varying(50) NULL,
ADD COLUMN "error" text NULL,
ADD COLUMN "message_order" integer NULL;

-- Add backend-specific columns to existing workflows table
ALTER TABLE "public"."workflows"
ADD COLUMN "module_id" character varying NULL,
ADD COLUMN "form_config" jsonb NULL,
ADD COLUMN "category" character varying(100) NULL,
ADD COLUMN "estimated_duration" integer NULL;

-- Add backend-specific columns to workflow_executions table
ALTER TABLE "public"."workflow_executions"
ADD COLUMN "progress" double precision NULL,
ADD COLUMN "form_data" jsonb NULL;

-- Create "workflow_modules" table (missing from enterprise schema)
CREATE TABLE "public"."workflow_modules" (
  "id" character varying NOT NULL,
  "created_at" timestamptz NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamptz NULL DEFAULT CURRENT_TIMESTAMP,
  "is_active" boolean NULL DEFAULT true,
  "name" character varying NOT NULL,
  "icon" character varying NOT NULL,
  "order" integer NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "workflow_modules_name_key" UNIQUE ("name")
);

-- Create index for workflow_modules
CREATE INDEX "ix_workflow_modules_id" ON "public"."workflow_modules" ("id");

-- Add foreign key constraint from workflows to workflow_modules
ALTER TABLE "public"."workflows"
ADD CONSTRAINT "workflows_module_id_fkey" FOREIGN KEY ("module_id") REFERENCES "public"."workflow_modules" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION;

-- Add backend-specific columns to existing conversations table (chats = conversations)
ALTER TABLE "public"."conversations"
ADD COLUMN "is_archived" boolean NULL DEFAULT false;

-- Create "uploaded_files" table (missing from enterprise schema)
CREATE TABLE "public"."uploaded_files" (
  "id" character varying NOT NULL,
  "created_at" timestamptz NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" timestamptz NULL DEFAULT CURRENT_TIMESTAMP,
  "is_active" boolean NULL DEFAULT true,
  "name" character varying NOT NULL,
  "original_name" character varying NOT NULL,
  "file_type" character varying NOT NULL,
  "file_size" integer NOT NULL,
  "file_path" character varying NOT NULL,
  "upload_status" character varying NULL,
  "user_id" character varying NOT NULL,
  "message_id" uuid NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "uploaded_files_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "public"."chat_messages" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);

-- Create index for uploaded_files
CREATE INDEX "ix_uploaded_files_id" ON "public"."uploaded_files" ("id");