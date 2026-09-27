CREATE TYPE "public"."content_status" AS ENUM('draft', 'published', 'archived');--> statement-breakpoint
CREATE TYPE "public"."difficulty" AS ENUM('easy', 'medium', 'hard');--> statement-breakpoint
CREATE TYPE "public"."question_type" AS ENUM('mcq', 'true_false', 'written');--> statement-breakpoint
CREATE TABLE "question_answers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"question_id" uuid NOT NULL,
	"answer_original" text NOT NULL,
	"answer_normalized" text NOT NULL,
	"normalization_version" integer NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "question_options" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"question_id" uuid NOT NULL,
	"text" text NOT NULL,
	"is_correct" boolean DEFAULT false NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE TABLE "questions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"type" "question_type" NOT NULL,
	"subject_id" uuid NOT NULL,
	"teacher_track_id" uuid,
	"unit_id" uuid,
	"lesson_id" uuid,
	"question_text" text NOT NULL,
	"explanation" text,
	"difficulty" "difficulty",
	"is_free" boolean DEFAULT false NOT NULL,
	"free_source" "free_source" DEFAULT 'rule' NOT NULL,
	"status" "content_status" DEFAULT 'draft' NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"content_version" integer DEFAULT 1 NOT NULL,
	"created_by_admin_id" uuid,
	"updated_by_admin_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone,
	CONSTRAINT "questions_version_ck" CHECK ("questions"."content_version" >= 1)
);
--> statement-breakpoint
ALTER TABLE "question_answers" ADD CONSTRAINT "question_answers_question_id_questions_id_fk" FOREIGN KEY ("question_id") REFERENCES "public"."questions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "question_options" ADD CONSTRAINT "question_options_question_id_questions_id_fk" FOREIGN KEY ("question_id") REFERENCES "public"."questions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "questions" ADD CONSTRAINT "questions_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "questions" ADD CONSTRAINT "questions_created_by_admin_id_users_id_fk" FOREIGN KEY ("created_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "questions" ADD CONSTRAINT "questions_updated_by_admin_id_users_id_fk" FOREIGN KEY ("updated_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "questions" ADD CONSTRAINT "questions_track_subject_fk" FOREIGN KEY ("teacher_track_id","subject_id") REFERENCES "public"."teacher_tracks"("id","subject_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "questions" ADD CONSTRAINT "questions_unit_subject_fk" FOREIGN KEY ("unit_id","subject_id") REFERENCES "public"."units"("id","subject_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "questions" ADD CONSTRAINT "questions_lesson_subject_fk" FOREIGN KEY ("lesson_id","subject_id") REFERENCES "public"."lessons"("id","subject_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "question_answers_question_idx" ON "question_answers" USING btree ("question_id");--> statement-breakpoint
CREATE UNIQUE INDEX "question_answers_active_uq" ON "question_answers" USING btree ("question_id","answer_normalized") WHERE is_active;--> statement-breakpoint
CREATE INDEX "question_options_question_sort_idx" ON "question_options" USING btree ("question_id","sort_order");--> statement-breakpoint
CREATE UNIQUE INDEX "question_options_one_correct" ON "question_options" USING btree ("question_id") WHERE is_correct;--> statement-breakpoint
CREATE INDEX "questions_scope_status_sort_idx" ON "questions" USING btree ("subject_id","teacher_track_id","status","sort_order");--> statement-breakpoint
CREATE INDEX "questions_unit_idx" ON "questions" USING btree ("unit_id");--> statement-breakpoint
CREATE INDEX "questions_lesson_idx" ON "questions" USING btree ("lesson_id");