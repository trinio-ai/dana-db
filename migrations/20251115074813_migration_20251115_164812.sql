-- Create "workflow_bookmarks" table
CREATE TABLE "public"."workflow_bookmarks" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "user_id" uuid NOT NULL,
  "workflow_id" uuid NOT NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "workflow_bookmarks_user_id_workflow_id_key" UNIQUE ("user_id", "workflow_id"),
  CONSTRAINT "workflow_bookmarks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "workflow_bookmarks_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "public"."workflows" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_workflow_bookmarks_user" to table: "workflow_bookmarks"
CREATE INDEX "idx_workflow_bookmarks_user" ON "public"."workflow_bookmarks" ("user_id");
-- Create index "idx_workflow_bookmarks_user_created" to table: "workflow_bookmarks"
CREATE INDEX "idx_workflow_bookmarks_user_created" ON "public"."workflow_bookmarks" ("user_id", "created_at" DESC);
-- Create index "idx_workflow_bookmarks_workflow" to table: "workflow_bookmarks"
CREATE INDEX "idx_workflow_bookmarks_workflow" ON "public"."workflow_bookmarks" ("workflow_id");
