CREATE TYPE "public"."import_format" AS ENUM('csv', 'xlsx');--> statement-breakpoint
CREATE TYPE "public"."import_kind" AS ENUM('mcq', 'true_false', 'written');--> statement-breakpoint
CREATE TYPE "public"."import_status" AS ENUM('parsing', 'ready', 'failed', 'importing', 'completed');--> statement-breakpoint
CREATE TABLE "import_errors" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"job_id" uuid NOT NULL,
	"row_number" integer NOT NULL,
	"field" text,
	"message" text NOT NULL
);
--> statement-breakpoint
CREATE TABLE "import_jobs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"kind" "import_kind" NOT NULL,
	"format" "import_format" NOT NULL,
	"file_name" text NOT NULL,
	"status" "import_status" DEFAULT 'parsing' NOT NULL,
	"total_rows" integer DEFAULT 0 NOT NULL,
	"valid_rows" integer DEFAULT 0 NOT NULL,
	"error_count" integer DEFAULT 0 NOT NULL,
	"file_data" text,
	"rows" jsonb,
	"summary" jsonb,
	"failure_reason" text,
	"created_by_admin_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"completed_at" timestamp with time zone
);
--> statement-breakpoint
ALTER TABLE "question_stats" ADD COLUMN "flag_reviewed_attempts" integer DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "import_errors" ADD CONSTRAINT "import_errors_job_id_import_jobs_id_fk" FOREIGN KEY ("job_id") REFERENCES "public"."import_jobs"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "import_jobs" ADD CONSTRAINT "import_jobs_created_by_admin_id_users_id_fk" FOREIGN KEY ("created_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "import_errors_job_row_idx" ON "import_errors" USING btree ("job_id","row_number");--> statement-breakpoint
CREATE INDEX "import_jobs_created_idx" ON "import_jobs" USING btree ("created_at");