CREATE TABLE "question_categories" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"subject_id" uuid,
	"parent_id" uuid,
	"code" text NOT NULL,
	"name_ar" text NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone,
	CONSTRAINT "question_categories_not_own_parent_ck" CHECK ("question_categories"."parent_id" is null or "question_categories"."parent_id" <> "question_categories"."id")
);
--> statement-breakpoint
ALTER TABLE "flashcards" ALTER COLUMN "back_media_id" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "questions" ADD COLUMN "category_id" uuid;--> statement-breakpoint
ALTER TABLE "quiz_attempt_answers" ADD COLUMN "marked_correct_by_student" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "user_decks" ADD COLUMN "template_key" text;--> statement-breakpoint
ALTER TABLE "question_categories" ADD CONSTRAINT "question_categories_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "question_categories" ADD CONSTRAINT "question_categories_parent_id_question_categories_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."question_categories"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "question_categories_subject_code_live_idx" ON "question_categories" USING btree ("subject_id","code") WHERE deleted_at is null and subject_id is not null;--> statement-breakpoint
CREATE UNIQUE INDEX "question_categories_global_code_live_idx" ON "question_categories" USING btree ("code") WHERE deleted_at is null and subject_id is null;--> statement-breakpoint
CREATE INDEX "question_categories_parent_idx" ON "question_categories" USING btree ("parent_id");--> statement-breakpoint
ALTER TABLE "questions" ADD CONSTRAINT "questions_category_id_question_categories_id_fk" FOREIGN KEY ("category_id") REFERENCES "public"."question_categories"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "questions_category_idx" ON "questions" USING btree ("category_id");