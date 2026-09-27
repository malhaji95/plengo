CREATE TYPE "public"."srs_rating" AS ENUM('again', 'good', 'easy');--> statement-breakpoint
CREATE TYPE "public"."srs_state" AS ENUM('new', 'learning', 'review', 'relearning');--> statement-breakpoint
CREATE TABLE "flashcard_decks" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"subject_id" uuid NOT NULL,
	"teacher_track_id" uuid,
	"unit_id" uuid,
	"lesson_id" uuid,
	"title_ar" text NOT NULL,
	"description" text,
	"cover_media_id" uuid,
	"is_free" boolean DEFAULT false NOT NULL,
	"free_source" "free_source" DEFAULT 'rule' NOT NULL,
	"status" "content_status" DEFAULT 'draft' NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"content_version" integer DEFAULT 1 NOT NULL,
	"created_by_admin_id" uuid,
	"updated_by_admin_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "flashcards" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"deck_id" uuid NOT NULL,
	"front_media_id" uuid NOT NULL,
	"back_media_id" uuid NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"status" "content_status" DEFAULT 'published' NOT NULL,
	"content_version" integer DEFAULT 1 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "card_states" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"flashcard_id" uuid,
	"user_card_id" uuid,
	"state" "srs_state" NOT NULL,
	"step" integer DEFAULT 0 NOT NULL,
	"due_at" timestamp with time zone NOT NULL,
	"interval_days" integer DEFAULT 0 NOT NULL,
	"ease" double precision NOT NULL,
	"reps" integer DEFAULT 0 NOT NULL,
	"lapses" integer DEFAULT 0 NOT NULL,
	"last_reviewed_at" timestamp with time zone,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "card_states_card_ck" CHECK (("card_states"."flashcard_id" is null) <> ("card_states"."user_card_id" is null))
);
--> statement-breakpoint
CREATE TABLE "review_logs" (
	"id" uuid PRIMARY KEY NOT NULL,
	"user_id" uuid NOT NULL,
	"flashcard_id" uuid,
	"user_card_id" uuid,
	"rating" "srs_rating" NOT NULL,
	"state_before" jsonb NOT NULL,
	"state_after" jsonb NOT NULL,
	"reviewed_at" timestamp with time zone NOT NULL,
	"duration_ms" integer,
	"undone" boolean DEFAULT false NOT NULL,
	"device_platform" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "review_logs_card_ck" CHECK (("review_logs"."flashcard_id" is null) <> ("review_logs"."user_card_id" is null))
);
--> statement-breakpoint
ALTER TABLE "flashcard_decks" ADD CONSTRAINT "flashcard_decks_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "flashcard_decks" ADD CONSTRAINT "flashcard_decks_cover_media_id_media_files_id_fk" FOREIGN KEY ("cover_media_id") REFERENCES "public"."media_files"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "flashcard_decks" ADD CONSTRAINT "flashcard_decks_created_by_admin_id_users_id_fk" FOREIGN KEY ("created_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "flashcard_decks" ADD CONSTRAINT "flashcard_decks_updated_by_admin_id_users_id_fk" FOREIGN KEY ("updated_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "flashcard_decks" ADD CONSTRAINT "flashcard_decks_track_subject_fk" FOREIGN KEY ("teacher_track_id","subject_id") REFERENCES "public"."teacher_tracks"("id","subject_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "flashcard_decks" ADD CONSTRAINT "flashcard_decks_unit_subject_fk" FOREIGN KEY ("unit_id","subject_id") REFERENCES "public"."units"("id","subject_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "flashcard_decks" ADD CONSTRAINT "flashcard_decks_lesson_subject_fk" FOREIGN KEY ("lesson_id","subject_id") REFERENCES "public"."lessons"("id","subject_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "flashcards" ADD CONSTRAINT "flashcards_deck_id_flashcard_decks_id_fk" FOREIGN KEY ("deck_id") REFERENCES "public"."flashcard_decks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "flashcards" ADD CONSTRAINT "flashcards_front_media_id_media_files_id_fk" FOREIGN KEY ("front_media_id") REFERENCES "public"."media_files"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "flashcards" ADD CONSTRAINT "flashcards_back_media_id_media_files_id_fk" FOREIGN KEY ("back_media_id") REFERENCES "public"."media_files"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "card_states" ADD CONSTRAINT "card_states_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "card_states" ADD CONSTRAINT "card_states_flashcard_id_flashcards_id_fk" FOREIGN KEY ("flashcard_id") REFERENCES "public"."flashcards"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "review_logs" ADD CONSTRAINT "review_logs_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "review_logs" ADD CONSTRAINT "review_logs_flashcard_id_flashcards_id_fk" FOREIGN KEY ("flashcard_id") REFERENCES "public"."flashcards"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "flashcard_decks_scope_idx" ON "flashcard_decks" USING btree ("subject_id","teacher_track_id","status","sort_order");--> statement-breakpoint
CREATE INDEX "flashcard_decks_unit_idx" ON "flashcard_decks" USING btree ("unit_id");--> statement-breakpoint
CREATE INDEX "flashcard_decks_lesson_idx" ON "flashcard_decks" USING btree ("lesson_id");--> statement-breakpoint
CREATE INDEX "flashcards_deck_sort_idx" ON "flashcards" USING btree ("deck_id","sort_order");--> statement-breakpoint
CREATE UNIQUE INDEX "card_states_user_flashcard_uq" ON "card_states" USING btree ("user_id","flashcard_id");--> statement-breakpoint
CREATE UNIQUE INDEX "card_states_user_user_card_uq" ON "card_states" USING btree ("user_id","user_card_id");--> statement-breakpoint
CREATE INDEX "card_states_user_due_idx" ON "card_states" USING btree ("user_id","due_at");--> statement-breakpoint
CREATE INDEX "card_states_user_updated_idx" ON "card_states" USING btree ("user_id","updated_at");--> statement-breakpoint
CREATE INDEX "review_logs_user_reviewed_idx" ON "review_logs" USING btree ("user_id","reviewed_at");