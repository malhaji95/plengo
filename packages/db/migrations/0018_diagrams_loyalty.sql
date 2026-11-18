CREATE TYPE "public"."loyalty_reason" AS ENUM('review', 'correct_answer', 'redemption', 'refund', 'admin_adjust');--> statement-breakpoint
CREATE TYPE "public"."loyalty_redemption_status" AS ENUM('pending', 'fulfilled', 'cancelled');--> statement-breakpoint
CREATE TYPE "public"."loyalty_reward_kind" AS ENUM('unlock_deck', 'custom');--> statement-breakpoint
ALTER TYPE "public"."free_content_kind" ADD VALUE 'diagrams';--> statement-breakpoint
CREATE TABLE "diagram_labels" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"diagram_id" uuid NOT NULL,
	"number" integer NOT NULL,
	"x" double precision,
	"y" double precision,
	"answers" text[] NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	CONSTRAINT "diagram_labels_number_ck" CHECK ("diagram_labels"."number" >= 1),
	CONSTRAINT "diagram_labels_x_ck" CHECK ("diagram_labels"."x" is null or ("diagram_labels"."x" >= 0 and "diagram_labels"."x" <= 1)),
	CONSTRAINT "diagram_labels_y_ck" CHECK ("diagram_labels"."y" is null or ("diagram_labels"."y" >= 0 and "diagram_labels"."y" <= 1)),
	CONSTRAINT "diagram_labels_answers_ck" CHECK (cardinality("diagram_labels"."answers") >= 1)
);
--> statement-breakpoint
CREATE TABLE "diagrams" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"subject_id" uuid NOT NULL,
	"teacher_track_id" uuid,
	"unit_id" uuid,
	"lesson_id" uuid,
	"title_ar" text NOT NULL,
	"description" text,
	"image_media_id" uuid NOT NULL,
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
	CONSTRAINT "diagrams_version_ck" CHECK ("diagrams"."content_version" >= 1)
);
--> statement-breakpoint
CREATE TABLE "loyalty_ledger" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"delta" integer NOT NULL,
	"reason" "loyalty_reason" NOT NULL,
	"ref_id" text,
	"day" date NOT NULL,
	"note" text,
	"admin_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "loyalty_ledger_delta_ck" CHECK ("loyalty_ledger"."delta" <> 0)
);
--> statement-breakpoint
CREATE TABLE "loyalty_redemptions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"reward_id" uuid NOT NULL,
	"title_ar" text NOT NULL,
	"kind" "loyalty_reward_kind" NOT NULL,
	"cost_points" integer NOT NULL,
	"deck_id" uuid,
	"status" "loyalty_redemption_status" NOT NULL,
	"handled_by_admin_id" uuid,
	"handled_at" timestamp with time zone,
	"note" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "loyalty_rewards" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"title_ar" text NOT NULL,
	"description" text,
	"cost_points" integer NOT NULL,
	"kind" "loyalty_reward_kind" NOT NULL,
	"deck_id" uuid,
	"is_active" boolean DEFAULT true NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone,
	CONSTRAINT "loyalty_rewards_cost_ck" CHECK ("loyalty_rewards"."cost_points" > 0),
	CONSTRAINT "loyalty_rewards_deck_ck" CHECK (("loyalty_rewards"."kind" = 'unlock_deck') = ("loyalty_rewards"."deck_id" is not null))
);
--> statement-breakpoint
CREATE TABLE "student_deck_unlocks" (
	"user_id" uuid NOT NULL,
	"deck_id" uuid NOT NULL,
	"redemption_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "diagram_labels" ADD CONSTRAINT "diagram_labels_diagram_id_diagrams_id_fk" FOREIGN KEY ("diagram_id") REFERENCES "public"."diagrams"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "diagrams" ADD CONSTRAINT "diagrams_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "diagrams" ADD CONSTRAINT "diagrams_image_media_id_media_files_id_fk" FOREIGN KEY ("image_media_id") REFERENCES "public"."media_files"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "diagrams" ADD CONSTRAINT "diagrams_created_by_admin_id_users_id_fk" FOREIGN KEY ("created_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "diagrams" ADD CONSTRAINT "diagrams_updated_by_admin_id_users_id_fk" FOREIGN KEY ("updated_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "diagrams" ADD CONSTRAINT "diagrams_track_subject_fk" FOREIGN KEY ("teacher_track_id","subject_id") REFERENCES "public"."teacher_tracks"("id","subject_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "diagrams" ADD CONSTRAINT "diagrams_unit_subject_fk" FOREIGN KEY ("unit_id","subject_id") REFERENCES "public"."units"("id","subject_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "diagrams" ADD CONSTRAINT "diagrams_lesson_subject_fk" FOREIGN KEY ("lesson_id","subject_id") REFERENCES "public"."lessons"("id","subject_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loyalty_ledger" ADD CONSTRAINT "loyalty_ledger_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loyalty_ledger" ADD CONSTRAINT "loyalty_ledger_admin_id_users_id_fk" FOREIGN KEY ("admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loyalty_redemptions" ADD CONSTRAINT "loyalty_redemptions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loyalty_redemptions" ADD CONSTRAINT "loyalty_redemptions_reward_id_loyalty_rewards_id_fk" FOREIGN KEY ("reward_id") REFERENCES "public"."loyalty_rewards"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loyalty_redemptions" ADD CONSTRAINT "loyalty_redemptions_deck_id_flashcard_decks_id_fk" FOREIGN KEY ("deck_id") REFERENCES "public"."flashcard_decks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loyalty_redemptions" ADD CONSTRAINT "loyalty_redemptions_handled_by_admin_id_users_id_fk" FOREIGN KEY ("handled_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "loyalty_rewards" ADD CONSTRAINT "loyalty_rewards_deck_id_flashcard_decks_id_fk" FOREIGN KEY ("deck_id") REFERENCES "public"."flashcard_decks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "student_deck_unlocks" ADD CONSTRAINT "student_deck_unlocks_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "student_deck_unlocks" ADD CONSTRAINT "student_deck_unlocks_deck_id_flashcard_decks_id_fk" FOREIGN KEY ("deck_id") REFERENCES "public"."flashcard_decks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "student_deck_unlocks" ADD CONSTRAINT "student_deck_unlocks_redemption_id_loyalty_redemptions_id_fk" FOREIGN KEY ("redemption_id") REFERENCES "public"."loyalty_redemptions"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "diagram_labels_number_uq" ON "diagram_labels" USING btree ("diagram_id","number");--> statement-breakpoint
CREATE INDEX "diagram_labels_diagram_sort_idx" ON "diagram_labels" USING btree ("diagram_id","sort_order");--> statement-breakpoint
CREATE INDEX "diagrams_scope_status_sort_idx" ON "diagrams" USING btree ("subject_id","teacher_track_id","status","sort_order");--> statement-breakpoint
CREATE INDEX "diagrams_unit_idx" ON "diagrams" USING btree ("unit_id");--> statement-breakpoint
CREATE INDEX "diagrams_lesson_idx" ON "diagrams" USING btree ("lesson_id");--> statement-breakpoint
CREATE UNIQUE INDEX "loyalty_ledger_ref_uq" ON "loyalty_ledger" USING btree ("user_id","reason","ref_id","day") WHERE ref_id is not null;--> statement-breakpoint
CREATE INDEX "loyalty_ledger_user_day_idx" ON "loyalty_ledger" USING btree ("user_id","day");--> statement-breakpoint
CREATE INDEX "loyalty_ledger_user_created_idx" ON "loyalty_ledger" USING btree ("user_id","created_at");--> statement-breakpoint
CREATE INDEX "loyalty_redemptions_user_idx" ON "loyalty_redemptions" USING btree ("user_id","created_at");--> statement-breakpoint
CREATE INDEX "loyalty_redemptions_status_idx" ON "loyalty_redemptions" USING btree ("status","created_at");--> statement-breakpoint
CREATE UNIQUE INDEX "student_deck_unlocks_uq" ON "student_deck_unlocks" USING btree ("user_id","deck_id");