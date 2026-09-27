CREATE TABLE "academic_years" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"faculty_id" uuid NOT NULL,
	"code" text NOT NULL,
	"name_ar" text NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone,
	CONSTRAINT "academic_years_id_faculty_uq" UNIQUE("id","faculty_id")
);
--> statement-breakpoint
CREATE TABLE "faculties" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"university_id" uuid NOT NULL,
	"code" text NOT NULL,
	"name_ar" text NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone,
	CONSTRAINT "faculties_id_university_uq" UNIQUE("id","university_id")
);
--> statement-breakpoint
CREATE TABLE "lessons" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"subject_id" uuid NOT NULL,
	"unit_id" uuid,
	"code" text NOT NULL,
	"title_ar" text NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone,
	CONSTRAINT "lessons_id_subject_uq" UNIQUE("id","subject_id")
);
--> statement-breakpoint
CREATE TABLE "subjects" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"education_level_id" uuid NOT NULL,
	"university_id" uuid,
	"faculty_id" uuid,
	"academic_year_id" uuid,
	"code" text NOT NULL,
	"name_ar" text NOT NULL,
	"description" text,
	"cover_media_id" uuid,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone,
	CONSTRAINT "subjects_college_chain_ck" CHECK (("subjects"."academic_year_id" is null or "subjects"."faculty_id" is not null) and ("subjects"."faculty_id" is null or "subjects"."university_id" is not null))
);
--> statement-breakpoint
CREATE TABLE "units" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"subject_id" uuid NOT NULL,
	"code" text NOT NULL,
	"title_ar" text NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone,
	CONSTRAINT "units_id_subject_uq" UNIQUE("id","subject_id")
);
--> statement-breakpoint
CREATE TABLE "universities" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"code" text NOT NULL,
	"name_ar" text NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone
);
--> statement-breakpoint
ALTER TABLE "academic_years" ADD CONSTRAINT "academic_years_faculty_id_faculties_id_fk" FOREIGN KEY ("faculty_id") REFERENCES "public"."faculties"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "faculties" ADD CONSTRAINT "faculties_university_id_universities_id_fk" FOREIGN KEY ("university_id") REFERENCES "public"."universities"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "lessons" ADD CONSTRAINT "lessons_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "lessons" ADD CONSTRAINT "lessons_unit_subject_fk" FOREIGN KEY ("unit_id","subject_id") REFERENCES "public"."units"("id","subject_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "subjects" ADD CONSTRAINT "subjects_education_level_id_education_levels_id_fk" FOREIGN KEY ("education_level_id") REFERENCES "public"."education_levels"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "subjects" ADD CONSTRAINT "subjects_university_id_universities_id_fk" FOREIGN KEY ("university_id") REFERENCES "public"."universities"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "subjects" ADD CONSTRAINT "subjects_cover_media_id_media_files_id_fk" FOREIGN KEY ("cover_media_id") REFERENCES "public"."media_files"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "subjects" ADD CONSTRAINT "subjects_faculty_university_fk" FOREIGN KEY ("faculty_id","university_id") REFERENCES "public"."faculties"("id","university_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "subjects" ADD CONSTRAINT "subjects_year_faculty_fk" FOREIGN KEY ("academic_year_id","faculty_id") REFERENCES "public"."academic_years"("id","faculty_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "units" ADD CONSTRAINT "units_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "academic_years_code_live_idx" ON "academic_years" USING btree ("faculty_id","code") WHERE deleted_at is null;--> statement-breakpoint
CREATE UNIQUE INDEX "faculties_code_live_idx" ON "faculties" USING btree ("university_id","code") WHERE deleted_at is null;--> statement-breakpoint
CREATE UNIQUE INDEX "lessons_code_live_idx" ON "lessons" USING btree ("subject_id","code") WHERE deleted_at is null;--> statement-breakpoint
CREATE INDEX "lessons_subject_sort_idx" ON "lessons" USING btree ("subject_id","sort_order");--> statement-breakpoint
CREATE INDEX "lessons_unit_idx" ON "lessons" USING btree ("unit_id");--> statement-breakpoint
CREATE UNIQUE INDEX "subjects_code_live_idx" ON "subjects" USING btree ("code") WHERE deleted_at is null;--> statement-breakpoint
CREATE INDEX "subjects_level_sort_idx" ON "subjects" USING btree ("education_level_id","sort_order");--> statement-breakpoint
CREATE UNIQUE INDEX "units_code_live_idx" ON "units" USING btree ("subject_id","code") WHERE deleted_at is null;--> statement-breakpoint
CREATE INDEX "units_subject_sort_idx" ON "units" USING btree ("subject_id","sort_order");--> statement-breakpoint
CREATE UNIQUE INDEX "universities_code_live_idx" ON "universities" USING btree ("code") WHERE deleted_at is null;--> statement-breakpoint
ALTER TABLE "profiles" ADD CONSTRAINT "profiles_university_id_universities_id_fk" FOREIGN KEY ("university_id") REFERENCES "public"."universities"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "profiles" ADD CONSTRAINT "profiles_faculty_id_faculties_id_fk" FOREIGN KEY ("faculty_id") REFERENCES "public"."faculties"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "profiles" ADD CONSTRAINT "profiles_academic_year_id_academic_years_id_fk" FOREIGN KEY ("academic_year_id") REFERENCES "public"."academic_years"("id") ON DELETE set null ON UPDATE no action;