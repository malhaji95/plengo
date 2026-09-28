CREATE TYPE "public"."report_item_type" AS ENUM('question', 'flashcard');--> statement-breakpoint
CREATE TYPE "public"."report_reason" AS ENUM('wrong_answer', 'typo', 'unclear', 'image_problem', 'other');--> statement-breakpoint
CREATE TYPE "public"."report_status" AS ENUM('open', 'resolved', 'dismissed');--> statement-breakpoint
CREATE TYPE "public"."user_card_kind" AS ENUM('custom', 'official_ref');--> statement-breakpoint
CREATE TABLE "content_reports" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"item_type" "report_item_type" NOT NULL,
	"item_id" uuid NOT NULL,
	"reason" "report_reason" NOT NULL,
	"note" text,
	"status" "report_status" DEFAULT 'open' NOT NULL,
	"resolved_by_admin_id" uuid,
	"resolution_note" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"resolved_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "user_cards" (
	"id" uuid PRIMARY KEY NOT NULL,
	"deck_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"kind" "user_card_kind" NOT NULL,
	"front_text" text,
	"back_text" text,
	"front_media_id" uuid,
	"back_media_id" uuid,
	"official_flashcard_id" uuid,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	"updated_at" timestamp with time zone NOT NULL,
	"deleted_at" timestamp with time zone,
	"sync_seq" bigserial NOT NULL,
	CONSTRAINT "user_cards_kind_ck" CHECK (("user_cards"."kind" = 'official_ref') = ("user_cards"."official_flashcard_id" is not null))
);
--> statement-breakpoint
CREATE TABLE "user_decks" (
	"id" uuid PRIMARY KEY NOT NULL,
	"user_id" uuid NOT NULL,
	"name" text NOT NULL,
	"subject_id" uuid,
	"color" text,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	"updated_at" timestamp with time zone NOT NULL,
	"deleted_at" timestamp with time zone,
	"sync_seq" bigserial NOT NULL
);
--> statement-breakpoint
ALTER TABLE "content_reports" ADD CONSTRAINT "content_reports_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "content_reports" ADD CONSTRAINT "content_reports_resolved_by_admin_id_users_id_fk" FOREIGN KEY ("resolved_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_cards" ADD CONSTRAINT "user_cards_deck_id_user_decks_id_fk" FOREIGN KEY ("deck_id") REFERENCES "public"."user_decks"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_cards" ADD CONSTRAINT "user_cards_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_cards" ADD CONSTRAINT "user_cards_front_media_id_media_files_id_fk" FOREIGN KEY ("front_media_id") REFERENCES "public"."media_files"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_cards" ADD CONSTRAINT "user_cards_back_media_id_media_files_id_fk" FOREIGN KEY ("back_media_id") REFERENCES "public"."media_files"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_cards" ADD CONSTRAINT "user_cards_official_flashcard_id_flashcards_id_fk" FOREIGN KEY ("official_flashcard_id") REFERENCES "public"."flashcards"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_decks" ADD CONSTRAINT "user_decks_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_decks" ADD CONSTRAINT "user_decks_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "content_reports_status_created_idx" ON "content_reports" USING btree ("status","created_at");--> statement-breakpoint
CREATE INDEX "content_reports_user_created_idx" ON "content_reports" USING btree ("user_id","created_at");--> statement-breakpoint
CREATE INDEX "content_reports_item_idx" ON "content_reports" USING btree ("item_type","item_id");--> statement-breakpoint
CREATE INDEX "user_cards_user_seq_idx" ON "user_cards" USING btree ("user_id","sync_seq");--> statement-breakpoint
CREATE INDEX "user_cards_deck_idx" ON "user_cards" USING btree ("deck_id");--> statement-breakpoint
CREATE INDEX "user_decks_user_seq_idx" ON "user_decks" USING btree ("user_id","sync_seq");--> statement-breakpoint
ALTER TABLE "card_states" ADD CONSTRAINT "card_states_user_card_id_user_cards_id_fk" FOREIGN KEY ("user_card_id") REFERENCES "public"."user_cards"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "review_logs" ADD CONSTRAINT "review_logs_user_card_id_user_cards_id_fk" FOREIGN KEY ("user_card_id") REFERENCES "public"."user_cards"("id") ON DELETE cascade ON UPDATE no action;