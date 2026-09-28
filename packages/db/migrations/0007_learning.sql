CREATE TYPE "public"."activity_type" AS ENUM('question', 'quiz', 'deck');--> statement-breakpoint
CREATE TYPE "public"."attempt_mode" AS ENUM('practice', 'exam');--> statement-breakpoint
CREATE TYPE "public"."attempt_source" AS ENUM('curated', 'random', 'mistakes');--> statement-breakpoint
CREATE TYPE "public"."attempt_status" AS ENUM('in_progress', 'submitted', 'abandoned');--> statement-breakpoint
CREATE TYPE "public"."bookmark_item_type" AS ENUM('question', 'flashcard', 'user_card', 'deck');--> statement-breakpoint
CREATE TYPE "public"."mistake_status" AS ENUM('active', 'mastered', 'removed');--> statement-breakpoint
CREATE TYPE "public"."quiz_modes" AS ENUM('practice', 'exam', 'both');--> statement-breakpoint
CREATE TABLE "quiz_questions" (
	"quiz_id" uuid NOT NULL,
	"question_id" uuid NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	CONSTRAINT "quiz_questions_pk" PRIMARY KEY("quiz_id","question_id")
);
--> statement-breakpoint
CREATE TABLE "quizzes" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"title_ar" text NOT NULL,
	"description" text,
	"subject_id" uuid NOT NULL,
	"teacher_track_id" uuid,
	"unit_id" uuid,
	"lesson_id" uuid,
	"allowed_modes" "quiz_modes" DEFAULT 'both' NOT NULL,
	"time_limit_seconds" integer,
	"shuffle_questions" boolean DEFAULT false NOT NULL,
	"shuffle_options" boolean DEFAULT false NOT NULL,
	"passing_score_percent" integer,
	"max_attempts" integer,
	"is_mock_exam" boolean DEFAULT false NOT NULL,
	"allow_offline" boolean DEFAULT true NOT NULL,
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
	CONSTRAINT "quizzes_time_limit_ck" CHECK ("quizzes"."time_limit_seconds" is null or "quizzes"."time_limit_seconds" > 0),
	CONSTRAINT "quizzes_passing_ck" CHECK ("quizzes"."passing_score_percent" is null or "quizzes"."passing_score_percent" between 0 and 100),
	CONSTRAINT "quizzes_max_attempts_ck" CHECK ("quizzes"."max_attempts" is null or "quizzes"."max_attempts" > 0)
);
--> statement-breakpoint
CREATE TABLE "bookmarks" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"item_type" "bookmark_item_type" NOT NULL,
	"item_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "bookmarks_uq" UNIQUE("user_id","item_type","item_id")
);
--> statement-breakpoint
CREATE TABLE "question_stats" (
	"question_id" uuid PRIMARY KEY NOT NULL,
	"attempt_count" integer DEFAULT 0 NOT NULL,
	"correct_count" integer DEFAULT 0 NOT NULL,
	"total_time_ms" integer DEFAULT 0 NOT NULL,
	"option_distribution" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"flagged_for_review" boolean DEFAULT false NOT NULL,
	"last_attempt_at" timestamp with time zone,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "quiz_attempt_answers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"attempt_id" uuid NOT NULL,
	"question_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"selected_option_id" uuid,
	"written_answer" text,
	"is_correct" boolean,
	"graded_at" timestamp with time zone,
	"flagged" boolean DEFAULT false NOT NULL,
	"answered_at" timestamp with time zone,
	"time_spent_ms" integer,
	"question_snapshot" jsonb,
	CONSTRAINT "quiz_attempt_answers_uq" UNIQUE("attempt_id","question_id")
);
--> statement-breakpoint
CREATE TABLE "quiz_attempts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"client_attempt_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"quiz_id" uuid,
	"quiz_content_version" integer,
	"source" "attempt_source" NOT NULL,
	"mode" "attempt_mode" NOT NULL,
	"title_ar" text NOT NULL,
	"subject_id" uuid,
	"teacher_track_id" uuid,
	"filters" jsonb,
	"question_order" jsonb NOT NULL,
	"option_orders" jsonb NOT NULL,
	"status" "attempt_status" DEFAULT 'in_progress' NOT NULL,
	"started_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deadline_at" timestamp with time zone,
	"submitted_at" timestamp with time zone,
	"submitted_late" boolean DEFAULT false NOT NULL,
	"score_percent" integer,
	"correct_count" integer,
	"total_count" integer NOT NULL,
	"time_spent_ms" integer,
	"last_activity_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "quiz_attempts_client_uq" UNIQUE("user_id","client_attempt_id")
);
--> statement-breakpoint
CREATE TABLE "user_mistakes" (
	"user_id" uuid NOT NULL,
	"question_id" uuid NOT NULL,
	"first_wrong_at" timestamp with time zone NOT NULL,
	"last_wrong_at" timestamp with time zone NOT NULL,
	"wrong_count" integer DEFAULT 1 NOT NULL,
	"correct_streak" integer DEFAULT 0 NOT NULL,
	"status" "mistake_status" DEFAULT 'active' NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "user_mistakes_pk" PRIMARY KEY("user_id","question_id")
);
--> statement-breakpoint
CREATE TABLE "user_progress" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"subject_id" uuid NOT NULL,
	"teacher_track_id" uuid,
	"unit_id" uuid,
	"lesson_id" uuid,
	"last_activity_type" "activity_type" NOT NULL,
	"last_item_id" uuid,
	"last_activity_at" timestamp with time zone NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "user_progress_scope_uq" UNIQUE NULLS NOT DISTINCT("user_id","subject_id","teacher_track_id")
);
--> statement-breakpoint
CREATE TABLE "user_subject_stats" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"subject_id" uuid NOT NULL,
	"teacher_track_id" uuid,
	"answered" integer DEFAULT 0 NOT NULL,
	"correct" integer DEFAULT 0 NOT NULL,
	"time_ms" integer DEFAULT 0 NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "user_subject_stats_uq" UNIQUE NULLS NOT DISTINCT("user_id","subject_id","teacher_track_id")
);
--> statement-breakpoint
ALTER TABLE "quiz_questions" ADD CONSTRAINT "quiz_questions_quiz_id_quizzes_id_fk" FOREIGN KEY ("quiz_id") REFERENCES "public"."quizzes"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quiz_questions" ADD CONSTRAINT "quiz_questions_question_id_questions_id_fk" FOREIGN KEY ("question_id") REFERENCES "public"."questions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quizzes" ADD CONSTRAINT "quizzes_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quizzes" ADD CONSTRAINT "quizzes_created_by_admin_id_users_id_fk" FOREIGN KEY ("created_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quizzes" ADD CONSTRAINT "quizzes_updated_by_admin_id_users_id_fk" FOREIGN KEY ("updated_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quizzes" ADD CONSTRAINT "quizzes_track_subject_fk" FOREIGN KEY ("teacher_track_id","subject_id") REFERENCES "public"."teacher_tracks"("id","subject_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quizzes" ADD CONSTRAINT "quizzes_unit_subject_fk" FOREIGN KEY ("unit_id","subject_id") REFERENCES "public"."units"("id","subject_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quizzes" ADD CONSTRAINT "quizzes_lesson_subject_fk" FOREIGN KEY ("lesson_id","subject_id") REFERENCES "public"."lessons"("id","subject_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bookmarks" ADD CONSTRAINT "bookmarks_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "question_stats" ADD CONSTRAINT "question_stats_question_id_questions_id_fk" FOREIGN KEY ("question_id") REFERENCES "public"."questions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quiz_attempt_answers" ADD CONSTRAINT "quiz_attempt_answers_attempt_id_quiz_attempts_id_fk" FOREIGN KEY ("attempt_id") REFERENCES "public"."quiz_attempts"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quiz_attempt_answers" ADD CONSTRAINT "quiz_attempt_answers_question_id_questions_id_fk" FOREIGN KEY ("question_id") REFERENCES "public"."questions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quiz_attempt_answers" ADD CONSTRAINT "quiz_attempt_answers_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quiz_attempts" ADD CONSTRAINT "quiz_attempts_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quiz_attempts" ADD CONSTRAINT "quiz_attempts_quiz_id_quizzes_id_fk" FOREIGN KEY ("quiz_id") REFERENCES "public"."quizzes"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quiz_attempts" ADD CONSTRAINT "quiz_attempts_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "quiz_attempts" ADD CONSTRAINT "quiz_attempts_teacher_track_id_teacher_tracks_id_fk" FOREIGN KEY ("teacher_track_id") REFERENCES "public"."teacher_tracks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_mistakes" ADD CONSTRAINT "user_mistakes_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_mistakes" ADD CONSTRAINT "user_mistakes_question_id_questions_id_fk" FOREIGN KEY ("question_id") REFERENCES "public"."questions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_progress" ADD CONSTRAINT "user_progress_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_progress" ADD CONSTRAINT "user_progress_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_progress" ADD CONSTRAINT "user_progress_teacher_track_id_teacher_tracks_id_fk" FOREIGN KEY ("teacher_track_id") REFERENCES "public"."teacher_tracks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_progress" ADD CONSTRAINT "user_progress_unit_id_units_id_fk" FOREIGN KEY ("unit_id") REFERENCES "public"."units"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_progress" ADD CONSTRAINT "user_progress_lesson_id_lessons_id_fk" FOREIGN KEY ("lesson_id") REFERENCES "public"."lessons"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_subject_stats" ADD CONSTRAINT "user_subject_stats_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_subject_stats" ADD CONSTRAINT "user_subject_stats_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_subject_stats" ADD CONSTRAINT "user_subject_stats_teacher_track_id_teacher_tracks_id_fk" FOREIGN KEY ("teacher_track_id") REFERENCES "public"."teacher_tracks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "quiz_questions_question_idx" ON "quiz_questions" USING btree ("question_id");--> statement-breakpoint
CREATE INDEX "quizzes_scope_idx" ON "quizzes" USING btree ("subject_id","teacher_track_id","status","sort_order");--> statement-breakpoint
CREATE INDEX "quizzes_unit_idx" ON "quizzes" USING btree ("unit_id");--> statement-breakpoint
CREATE INDEX "quizzes_lesson_idx" ON "quizzes" USING btree ("lesson_id");--> statement-breakpoint
CREATE INDEX "bookmarks_user_created_idx" ON "bookmarks" USING btree ("user_id","created_at");--> statement-breakpoint
CREATE INDEX "quiz_attempt_answers_question_idx" ON "quiz_attempt_answers" USING btree ("question_id");--> statement-breakpoint
CREATE INDEX "quiz_attempt_answers_user_graded_idx" ON "quiz_attempt_answers" USING btree ("user_id","graded_at");--> statement-breakpoint
CREATE INDEX "quiz_attempts_user_started_idx" ON "quiz_attempts" USING btree ("user_id","started_at");--> statement-breakpoint
CREATE INDEX "quiz_attempts_user_status_idx" ON "quiz_attempts" USING btree ("user_id","status");--> statement-breakpoint
CREATE INDEX "quiz_attempts_quiz_idx" ON "quiz_attempts" USING btree ("quiz_id");--> statement-breakpoint
CREATE INDEX "quiz_attempts_activity_idx" ON "quiz_attempts" USING btree ("status","last_activity_at");--> statement-breakpoint
CREATE INDEX "user_mistakes_user_status_idx" ON "user_mistakes" USING btree ("user_id","status");--> statement-breakpoint
CREATE INDEX "user_progress_user_activity_idx" ON "user_progress" USING btree ("user_id","last_activity_at");