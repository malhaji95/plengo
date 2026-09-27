CREATE TYPE "public"."coupon_batch_status" AS ENUM('active', 'revoked');--> statement-breakpoint
CREATE TYPE "public"."coupon_status" AS ENUM('active', 'redeemed', 'revoked');--> statement-breakpoint
CREATE TYPE "public"."entitlement_source" AS ENUM('coupon', 'admin_grant', 'promotion', 'future_purchase');--> statement-breakpoint
CREATE TYPE "public"."entitlement_status" AS ENUM('active', 'revoked', 'expired', 'superseded');--> statement-breakpoint
CREATE TYPE "public"."free_content_kind" AS ENUM('questions', 'flashcard_decks', 'quizzes', 'all');--> statement-breakpoint
CREATE TYPE "public"."free_rule_type" AS ENUM('manual', 'first_n_items', 'first_n_lessons', 'first_unit', 'percentage');--> statement-breakpoint
CREATE TYPE "public"."free_source" AS ENUM('rule', 'manual_override');--> statement-breakpoint
CREATE TYPE "public"."scope_type" AS ENUM('subject', 'teacher_track');--> statement-breakpoint
CREATE TABLE "coupon_batches" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"distributor_name" text,
	"notes" text,
	"scope_type" "scope_type" NOT NULL,
	"subject_id" uuid,
	"teacher_track_id" uuid,
	"quantity" integer NOT NULL,
	"generated_count" integer DEFAULT 0 NOT NULL,
	"valid_from" timestamp with time zone,
	"expires_at" timestamp with time zone,
	"access_duration_days" integer,
	"access_expires_at" timestamp with time zone,
	"permanent_access" boolean DEFAULT false NOT NULL,
	"status" "coupon_batch_status" DEFAULT 'active' NOT NULL,
	"created_by_admin_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"revoked_at" timestamp with time zone,
	"revoked_by_admin_id" uuid,
	CONSTRAINT "coupon_batches_scope_ck" CHECK (("coupon_batches"."scope_type" = 'subject' and "coupon_batches"."subject_id" is not null and "coupon_batches"."teacher_track_id" is null)
     or ("coupon_batches"."scope_type" = 'teacher_track' and "coupon_batches"."teacher_track_id" is not null and "coupon_batches"."subject_id" is null)),
	CONSTRAINT "coupon_batches_quantity_ck" CHECK ("coupon_batches"."quantity" between 1 and 5000),
	CONSTRAINT "coupon_batches_access_ck" CHECK ((case when "coupon_batches"."permanent_access" then 1 else 0 end
        + case when "coupon_batches"."access_duration_days" is not null then 1 else 0 end
        + case when "coupon_batches"."access_expires_at" is not null then 1 else 0 end) = 1)
);
--> statement-breakpoint
CREATE TABLE "coupon_redemption_failures" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid,
	"ip_hash" text,
	"code_last4" text,
	"reason" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "coupon_redemptions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"coupon_id" uuid NOT NULL,
	"user_id" uuid,
	"redeemed_at" timestamp with time zone DEFAULT now() NOT NULL,
	"session_id" uuid,
	"entitlement_id" uuid NOT NULL,
	"ip_hash" text,
	CONSTRAINT "coupon_redemptions_coupon_user_uq" UNIQUE("coupon_id","user_id")
);
--> statement-breakpoint
CREATE TABLE "coupons" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"batch_id" uuid NOT NULL,
	"code_hash" text NOT NULL,
	"code_encrypted" text NOT NULL,
	"code_last4" text NOT NULL,
	"scope_type" "scope_type" NOT NULL,
	"subject_id" uuid,
	"teacher_track_id" uuid,
	"valid_from" timestamp with time zone,
	"expires_at" timestamp with time zone,
	"access_duration_days" integer,
	"access_expires_at" timestamp with time zone,
	"permanent_access" boolean DEFAULT false NOT NULL,
	"max_uses" integer DEFAULT 1 NOT NULL,
	"current_uses" integer DEFAULT 0 NOT NULL,
	"status" "coupon_status" DEFAULT 'active' NOT NULL,
	"created_by_admin_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "coupons_code_hash_uq" UNIQUE("code_hash"),
	CONSTRAINT "coupons_scope_ck" CHECK (("coupons"."scope_type" = 'subject' and "coupons"."subject_id" is not null and "coupons"."teacher_track_id" is null)
     or ("coupons"."scope_type" = 'teacher_track' and "coupons"."teacher_track_id" is not null and "coupons"."subject_id" is null)),
	CONSTRAINT "coupons_uses_ck" CHECK ("coupons"."current_uses" between 0 and "coupons"."max_uses")
);
--> statement-breakpoint
CREATE TABLE "entitlements" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"scope_type" "scope_type" NOT NULL,
	"subject_id" uuid,
	"teacher_track_id" uuid,
	"source" "entitlement_source" NOT NULL,
	"coupon_id" uuid,
	"granted_by_admin_id" uuid,
	"starts_at" timestamp with time zone DEFAULT now() NOT NULL,
	"expires_at" timestamp with time zone,
	"is_permanent" boolean DEFAULT false NOT NULL,
	"status" "entitlement_status" DEFAULT 'active' NOT NULL,
	"revoked_at" timestamp with time zone,
	"revoked_by_admin_id" uuid,
	"revoke_reason" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "entitlements_scope_ck" CHECK (("entitlements"."scope_type" = 'subject' and "entitlements"."subject_id" is not null and "entitlements"."teacher_track_id" is null)
     or ("entitlements"."scope_type" = 'teacher_track' and "entitlements"."teacher_track_id" is not null and "entitlements"."subject_id" is null)),
	CONSTRAINT "entitlements_term_ck" CHECK (("entitlements"."is_permanent" and "entitlements"."expires_at" is null) or (not "entitlements"."is_permanent" and "entitlements"."expires_at" is not null))
);
--> statement-breakpoint
CREATE TABLE "free_access_rules" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"scope_type" "scope_type" NOT NULL,
	"subject_id" uuid,
	"teacher_track_id" uuid,
	"content_kind" "free_content_kind" NOT NULL,
	"rule_type" "free_rule_type" NOT NULL,
	"rule_value" integer,
	"updated_by_admin_id" uuid,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "free_access_rules_scope_ck" CHECK (("free_access_rules"."scope_type" = 'subject' and "free_access_rules"."subject_id" is not null and "free_access_rules"."teacher_track_id" is null)
     or ("free_access_rules"."scope_type" = 'teacher_track' and "free_access_rules"."teacher_track_id" is not null and "free_access_rules"."subject_id" is null)),
	CONSTRAINT "free_access_rules_value_ck" CHECK (case "free_access_rules"."rule_type"
        when 'first_n_items' then "free_access_rules"."rule_value" >= 1
        when 'first_n_lessons' then "free_access_rules"."rule_value" >= 1
        when 'percentage' then "free_access_rules"."rule_value" between 1 and 100
        else "free_access_rules"."rule_value" is null end)
);
--> statement-breakpoint
CREATE TABLE "promotions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"scope_type" "scope_type" NOT NULL,
	"subject_id" uuid,
	"teacher_track_id" uuid,
	"title_ar" text NOT NULL,
	"starts_at" timestamp with time zone NOT NULL,
	"ends_at" timestamp with time zone NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_by_admin_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "promotions_scope_ck" CHECK (("promotions"."scope_type" = 'subject' and "promotions"."subject_id" is not null and "promotions"."teacher_track_id" is null)
     or ("promotions"."scope_type" = 'teacher_track' and "promotions"."teacher_track_id" is not null and "promotions"."subject_id" is null)),
	CONSTRAINT "promotions_window_ck" CHECK ("promotions"."ends_at" > "promotions"."starts_at")
);
--> statement-breakpoint
ALTER TABLE "coupon_batches" ADD CONSTRAINT "coupon_batches_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "coupon_batches" ADD CONSTRAINT "coupon_batches_teacher_track_id_teacher_tracks_id_fk" FOREIGN KEY ("teacher_track_id") REFERENCES "public"."teacher_tracks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "coupon_batches" ADD CONSTRAINT "coupon_batches_created_by_admin_id_users_id_fk" FOREIGN KEY ("created_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "coupon_batches" ADD CONSTRAINT "coupon_batches_revoked_by_admin_id_users_id_fk" FOREIGN KEY ("revoked_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "coupon_redemption_failures" ADD CONSTRAINT "coupon_redemption_failures_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "coupon_redemptions" ADD CONSTRAINT "coupon_redemptions_coupon_id_coupons_id_fk" FOREIGN KEY ("coupon_id") REFERENCES "public"."coupons"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "coupon_redemptions" ADD CONSTRAINT "coupon_redemptions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "coupon_redemptions" ADD CONSTRAINT "coupon_redemptions_session_id_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."sessions"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "coupon_redemptions" ADD CONSTRAINT "coupon_redemptions_entitlement_id_entitlements_id_fk" FOREIGN KEY ("entitlement_id") REFERENCES "public"."entitlements"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "coupons" ADD CONSTRAINT "coupons_batch_id_coupon_batches_id_fk" FOREIGN KEY ("batch_id") REFERENCES "public"."coupon_batches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "coupons" ADD CONSTRAINT "coupons_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "coupons" ADD CONSTRAINT "coupons_teacher_track_id_teacher_tracks_id_fk" FOREIGN KEY ("teacher_track_id") REFERENCES "public"."teacher_tracks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "coupons" ADD CONSTRAINT "coupons_created_by_admin_id_users_id_fk" FOREIGN KEY ("created_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entitlements" ADD CONSTRAINT "entitlements_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entitlements" ADD CONSTRAINT "entitlements_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entitlements" ADD CONSTRAINT "entitlements_teacher_track_id_teacher_tracks_id_fk" FOREIGN KEY ("teacher_track_id") REFERENCES "public"."teacher_tracks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entitlements" ADD CONSTRAINT "entitlements_coupon_id_coupons_id_fk" FOREIGN KEY ("coupon_id") REFERENCES "public"."coupons"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entitlements" ADD CONSTRAINT "entitlements_granted_by_admin_id_users_id_fk" FOREIGN KEY ("granted_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entitlements" ADD CONSTRAINT "entitlements_revoked_by_admin_id_users_id_fk" FOREIGN KEY ("revoked_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "free_access_rules" ADD CONSTRAINT "free_access_rules_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "free_access_rules" ADD CONSTRAINT "free_access_rules_teacher_track_id_teacher_tracks_id_fk" FOREIGN KEY ("teacher_track_id") REFERENCES "public"."teacher_tracks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "free_access_rules" ADD CONSTRAINT "free_access_rules_updated_by_admin_id_users_id_fk" FOREIGN KEY ("updated_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "promotions" ADD CONSTRAINT "promotions_subject_id_subjects_id_fk" FOREIGN KEY ("subject_id") REFERENCES "public"."subjects"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "promotions" ADD CONSTRAINT "promotions_teacher_track_id_teacher_tracks_id_fk" FOREIGN KEY ("teacher_track_id") REFERENCES "public"."teacher_tracks"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "promotions" ADD CONSTRAINT "promotions_created_by_admin_id_users_id_fk" FOREIGN KEY ("created_by_admin_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "coupon_redemption_failures_user_idx" ON "coupon_redemption_failures" USING btree ("user_id","created_at");--> statement-breakpoint
CREATE INDEX "coupon_redemption_failures_ip_idx" ON "coupon_redemption_failures" USING btree ("ip_hash","created_at");--> statement-breakpoint
CREATE INDEX "coupon_redemptions_user_idx" ON "coupon_redemptions" USING btree ("user_id","redeemed_at");--> statement-breakpoint
CREATE INDEX "coupon_redemptions_ip_idx" ON "coupon_redemptions" USING btree ("ip_hash","redeemed_at");--> statement-breakpoint
CREATE INDEX "coupons_batch_idx" ON "coupons" USING btree ("batch_id");--> statement-breakpoint
CREATE INDEX "coupons_last4_idx" ON "coupons" USING btree ("code_last4");--> statement-breakpoint
CREATE UNIQUE INDEX "entitlements_one_active_subject" ON "entitlements" USING btree ("user_id","subject_id") WHERE status = 'active' and scope_type = 'subject';--> statement-breakpoint
CREATE UNIQUE INDEX "entitlements_one_active_track" ON "entitlements" USING btree ("user_id","teacher_track_id") WHERE status = 'active' and scope_type = 'teacher_track';--> statement-breakpoint
CREATE INDEX "entitlements_user_scope_idx" ON "entitlements" USING btree ("user_id","scope_type","subject_id","teacher_track_id","status");--> statement-breakpoint
CREATE INDEX "entitlements_expires_idx" ON "entitlements" USING btree ("expires_at");--> statement-breakpoint
CREATE UNIQUE INDEX "free_access_rules_subject_kind_uq" ON "free_access_rules" USING btree ("subject_id","content_kind") WHERE scope_type = 'subject';--> statement-breakpoint
CREATE UNIQUE INDEX "free_access_rules_track_kind_uq" ON "free_access_rules" USING btree ("teacher_track_id","content_kind") WHERE scope_type = 'teacher_track';--> statement-breakpoint
CREATE INDEX "promotions_subject_idx" ON "promotions" USING btree ("subject_id");--> statement-breakpoint
CREATE INDEX "promotions_track_idx" ON "promotions" USING btree ("teacher_track_id");