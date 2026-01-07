-- Create "organization_data_rules" table
CREATE TABLE "public"."organization_data_rules" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid NOT NULL,
  "system_instructions" text NULL,
  "global_settings" jsonb NULL DEFAULT '{"currency": "KRW", "date_format": "YYYY-MM-DD", "decimal_places": 2, "default_territory": null, "default_warehouse": null}',
  "is_active" boolean NULL DEFAULT true,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  "created_by" uuid NULL,
  "updated_by" uuid NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "organization_data_rules_organization_id_key" UNIQUE ("organization_id"),
  CONSTRAINT "organization_data_rules_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT "organization_data_rules_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations" ("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT "organization_data_rules_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "public"."users" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);
-- Create index "idx_org_data_rules_active" to table: "organization_data_rules"
CREATE INDEX "idx_org_data_rules_active" ON "public"."organization_data_rules" ("is_active");
-- Create index "idx_org_data_rules_org_id" to table: "organization_data_rules"
CREATE INDEX "idx_org_data_rules_org_id" ON "public"."organization_data_rules" ("organization_id");
-- Create "organization_doctype_rules" table
CREATE TABLE "public"."organization_doctype_rules" (
  "id" uuid NOT NULL DEFAULT gen_random_uuid(),
  "organization_data_rules_id" uuid NOT NULL,
  "doctype" character varying(140) NOT NULL,
  "create_rules" jsonb NULL DEFAULT '{"enabled": true, "validations": [], "auto_set_fields": {}, "required_fields": [], "forbidden_fields": []}',
  "update_rules" jsonb NULL DEFAULT '{"enabled": true, "validations": [], "protected_fields": []}',
  "delete_rules" jsonb NULL DEFAULT '{"enabled": true, "forbidden": false, "conditions": [], "forbidden_message": null, "require_confirmation": false}',
  "doctype_instructions" text NULL,
  "created_at" timestamptz NULL DEFAULT now(),
  "updated_at" timestamptz NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  CONSTRAINT "organization_doctype_rules_organization_data_rules_id_docty_key" UNIQUE ("organization_data_rules_id", "doctype"),
  CONSTRAINT "organization_doctype_rules_organization_data_rules_id_fkey" FOREIGN KEY ("organization_data_rules_id") REFERENCES "public"."organization_data_rules" ("id") ON UPDATE NO ACTION ON DELETE CASCADE
);
-- Create index "idx_doctype_rules_doctype" to table: "organization_doctype_rules"
CREATE INDEX "idx_doctype_rules_doctype" ON "public"."organization_doctype_rules" ("doctype");
-- Create index "idx_doctype_rules_parent" to table: "organization_doctype_rules"
CREATE INDEX "idx_doctype_rules_parent" ON "public"."organization_doctype_rules" ("organization_data_rules_id");
