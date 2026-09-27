CREATE TABLE "teacher_followers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"teacher_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "teacher_followers_teacher_user_uq" UNIQUE("teacher_id","user_id")
);
--> statement-breakpoint
CREATE TABLE "teacher_tracks" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"teacher_id" uuid NOT NULL,
	"subject_id" uuid NOT NULL,
	"title_ar" text NOT NULL,
	"slug" text NOT NULL,
	"description" text,
	"cover_media_id" uuid,
	"is_active" boolean DEFAULT true NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone,
	CONSTRAINT "teacher_tracks_id_subject_uq" UNIQUE("id","subject_id")
);
--> statement-breakpoint
CREATE TABLE "teachers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name_ar" text NOT NULL,
	"slug" text NOT NULL,
	"photo_media_id" uuid,
	"short_description" text,
	"bio" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone
);
--> statement-breakpoint
ALTER TABLE "teacher_followers" ADD CONSTRAINT "teacher_followers_teacher_id_teachers_id_fk" FOREIGN KEY ("teacher_id") REFERENCES "public"."teachers"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "teacher_followers" ADD CONSTRAINT "teacher_followers_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "teacher_tracks" ADD CONSTRAINT "teacher_tracks_teacher_id_teachers_id_fk" FOREIGN KEY ("teacher_id") REFERENCES "public"."teachers"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "teacher_tracks" ADD CONSTRAINT "teacher_tracks_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "teacher_tracks" ADD CONSTRAINT "teacher_tracks_cover_media_id_media_files_id_fk" FOREIGN KEY ("cover_media_id") REFERENCES "public"."media_files"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "teachers" ADD CONSTRAINT "teachers_photo_media_id_media_files_id_fk" FOREIGN KEY ("photo_media_id") REFERENCES "public"."media_files"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "teacher_followers_user_idx" ON "teacher_followers" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "teacher_followers_teacher_idx" ON "teacher_followers" USING btree ("teacher_id");--> statement-breakpoint
CREATE UNIQUE INDEX "teacher_tracks_slug_live_idx" ON "teacher_tracks" USING btree ("slug") WHERE deleted_at is null;--> statement-breakpoint
CREATE INDEX "teacher_tracks_teacher_sort_idx" ON "teacher_tracks" USING btree ("teacher_id","sort_order");--> statement-breakpoint
CREATE INDEX "teacher_tracks_subject_idx" ON "teacher_tracks" USING btree ("subject_id");--> statement-breakpoint
CREATE UNIQUE INDEX "teachers_slug_live_idx" ON "teachers" USING btree ("slug") WHERE deleted_at is null;