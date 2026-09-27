-- Fixed education levels (spec §1, §40). Keep in sync with src/seed-data.ts.
INSERT INTO "education_levels" ("code", "name_ar", "sort_order") VALUES
  ('grade-9', 'الصف التاسع', 1),
  ('grade-12', 'البكالوريا', 2),
  ('college', 'الجامعة', 3)
ON CONFLICT ("code") DO NOTHING;
