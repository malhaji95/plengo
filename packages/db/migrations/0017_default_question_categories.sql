-- Global default question categories (v3 §3). Admins may rename, reorder or delete them.
INSERT INTO "question_categories" ("subject_id", "code", "name_ar", "sort_order")
SELECT NULL, v.code, v.name_ar, v.sort_order
FROM (VALUES
  ('explain', 'علل', 1),
  ('what-results', 'ماذا ينتج', 2),
  ('compare', 'قارن', 3),
  ('order', 'رتّب', 4),
  ('define', 'عرّف', 5),
  ('fill-blank', 'أكمل الفراغ', 6),
  ('true-false', 'صح أم خطأ', 7),
  ('choose-correct', 'اختر الإجابة الصحيحة', 8)
) AS v(code, name_ar, sort_order)
WHERE NOT EXISTS (
  SELECT 1 FROM "question_categories" c
  WHERE c."subject_id" IS NULL AND c."code" = v.code AND c."deleted_at" IS NULL
);
