# Plengo v3 — owner's edits (PDF «التعديلات التصميمية», 12 pages)

Owner decisions (asked 2026-11-17):

- Navigation: **side drawer + bottom bar**. Bottom bar keeps the 4 main places; the drawer lists
  everything.
- First 3 lessons of every subject are **free by default**; the number is a setting the admin can
  change (and the existing per-subject free rules still override it).
- Deliver **one APK when every phase is done**.
- Loyalty programme **last**, with rules the admin can edit.

Everything below keeps the existing rules in CLAUDE.md (RTL, Arabic, envelope, migrations, generated
clients, 48 dp, light/dark, 3 font sizes, COUPON_REDEMPTION compile-time flag) and the redesign v2
design system in `apps/mobile/lib/shared/ui/`.

## 1. Navigation and entry

1. **Splash** («V3-Splash»): yellow background, the **blue** logo, a short motion intro, and the
   slogan «صديقك لمراجعة أسرع وأمتع». The motion is built in code (logo scale/fade + confetti dots,
   ≤ 1.5 s, skipped with reduce-motion) with a slot for the owner's video
   (`assets/brand/splash_motion.mp4` — if the file is present it plays instead; no new heavy
   dependency unless the video arrives).
2. **Side drawer** (opened from a ☰ button at the start of the app bar on every main screen): Plengo
   blue logo on top, rows with icon + label, the active row filled yellow, and an illustration slot
   at the bottom (`assets/brand/drawer_art.png`, 600 × 900 px, transparent PNG; a placeholder made of
   brand shapes until it arrives). Items, in order:
   1. الرئيسية · 2. المواد · 3. موادي · 4. تدرّب · 5. فلاش كاردز بلينغو · 6. اصنع بطاقاتك الخاصة ·
   7. حسابي — plus, under a divider, المحفوظات and المراجعة (they keep their screens).
3. **Bottom bar**: الرئيسية · المواد · تدرّب · موادي · حسابي (5 tabs, yellow pill as now). On wide
   screens the drawer is the permanent side rail (all items).

## 2. Home

- «مرحباً، الطالب» header with the bell (notifications include offers/discounts — the existing
  `promotion` type; keep the opt-in rule).
- **Continue** hero: only the latest item; remove the extra resume rows under it.
- **«راجع الدرس التالي:»** — new auto-scrolling carousel of circular lesson tiles (lesson name +
  subject, subject hue, big centre tile with a ▶ button, side arrows, dots). It moves by itself
  every ~4 s (paused while touched; no motion with reduce-motion). Data: for each subject in
  «موادي» (active access) the next lesson below 100 % (from the progress endpoint), plus free
  subjects if the student has no access yet.
- **Today**: daily goal ring as now; «مراجعة البطاقات المستحقة» opens **موادي**; the mistakes row is
  replaced by **«مراجعة البطاقات الصعبة»** (cards the student found hard) which opens the saved
  cards (المحفوظات ← البطاقات).
- **Banners**: several banners, auto-rotating every ~5 s (dots, swipe, pause on touch).
- «موادّي ومساراتي» and «محتوى مجاني» stay (as now).

## 3. Subjects (المواد) and subject page

- Subject page as in the physics screenshot: illustrated blue header (per-subject header art slot
  `assets/subjects/<subject code>.png`, 1080 × 480; generic science doodles until provided).
- **Remove** the «هذا المحتوى يحتاج إلى تفعيل» box and the «وحدة واحدة مكتملة» row.
- **Stations** (path nodes): locked = black & white with a lock; tapping a locked station opens a
  sheet «هذا المحتوى يحتاج إلى تفعيل» → activation code; started (some progress) = **blue**;
  finished = **green**; not started but open = white/outlined.
- **Free by default**: the first N lessons of every subject (N = setting `defaultFreeLessons`,
  default 3, by unit order then lesson order; loose lessons after units) are free, unless the
  subject has its own free rule.
- The 4 shortcuts under the subject name: **تدريب** (→ تدرّب for this subject) · **بطاقات بلينغو**
  (→ Plengo flashcards of this subject) · **راجع أخطاءك** (→ saved cards of this subject) ·
  **بطاقاتي** (→ the student's own groups for this subject).
- **Lesson page** groups the lesson's questions by **question category** (e.g. علل · ماذا ينتج ·
  قارن · رتّب · عرّف · أكمل الفراغ · صح أم خطأ · اختر الإجابة الصحيحة), with parent/child categories.

## 4. موادي

Like the review tab but per purchased subject: each subject the student has access to, how far they
got (completion %, current lesson), «مراجعة البطاقات الصعبة» instead of mistakes, «بطاقاتي» (opens the
lessons path with progress), «إحصائياتي».

## 5. تدرّب (practice)

- Page: header «تدريب»; grid of the student's level subjects (icon + name + subject hue); section
  **«اختبارات بلينغو المخصصة»** (first entry: «رسمات العلوم»).
- Practice setup for a subject: unit carousel (cards per unit) → lessons multi-select (checkboxes) →
  **question categories** multi-select → question types → count **10 · 20 · 30 · جميع الأسئلة** →
  «ابدأ التدريب». **Practice only** (no exam mode here).
- **Written answers**: exact (normalised) match = correct. Otherwise show the model answer in the
  explanation box and two buttons: «إجابتي خاطئة» / «إجابتي صحيحة لكن بصياغة مختلفة». The second
  counts the answer as correct (for attempts the server records the override; bank practice counts it
  in the session score).

## 6. فلاش كاردز بلينغو

- Page listing the official decks as products: product (box) image = deck cover, title, subtitle,
  coloured card per subject; grouped by subject pills.
- Locked decks: the first **5** cards can be browsed; then the locked notice → activation.
- Long cards scroll vertically inside the card.
- **Single-face cards**: a card may have only a front image (a ready-made card designed by the
  owner); it shows without flipping. Admin bulk upload accepts cards with no back.

## 7. اصنع بطاقاتك الخاصة

1. Subject carousel → choose a template (frames per subject: the owner's physics and medical frames
   plus four built-in ones) → «ابدأ الإنشاء».
2. Group name → cards one by one: front (text) and back (text and/or image upload) → «التالي» …
   «انتهت المجموعة».
3. Done screen «تم إنشاء مجموعة الفلاش كاردز!» with the cards list, «إضافة بطاقات أخرى».
4. «مجموعاتي»: groups per subject with «مراجعة» and «تعديل»; group page with preview carousel,
   «إضافة بطاقات», «تعديل المجموعة», مراجعة المجموعة, عرض البطاقات, إعدادات المجموعة, إحصائيات
   التقدم. Edit group: تعديل البطاقات · إضافة بطاقات · حذف المجموعة.
5. Cards render on the chosen template frame.

## 8. Stars (★) and saved cards

- A ★ on every card (official and own). Starred cards are saved under the deck's name and filed under
  subject → unit → deck in المحفوظات (e.g. اللغة الإنكليزية › Unit 1 › Vocabulary — 50 ★).
- «البطاقات الصعبة»: cards with at least two «مرة أخرى» lapses or a low ease, from the device's SRS
  states; plus the starred ones.

## 9. اختبارات بلينغو المخصصة — «رسمات العلوم»

- New content type **diagram**: an image with numbered labels; each label has one or more accepted
  answers. Placed by subject/unit/lesson like questions; admin CRUD (upload the image, add labels and
  answers) and bulk import (Excel + images).
- Flow: choose «وحدة كاملة» / «عدة دروس» / «درس واحد», the unit/lessons, the number of diagrams
  (− / +) → for each diagram the student types the name of each numbered part → check (per diagram
  or only at the end, the student's choice) → results (score %, correct answers, diagrams) with
  «إعادة التدريب» / «تدريب آخر».

## 10. Loyalty (last)

Points for reviewed cards (rules editable in the admin settings: points per review, daily cap);
a rewards list (e.g. unlock a Plengo deck for N points). Built last.

## Assets the owner will send (slots ready, placeholders until then)

| Asset | Size | Path |
|---|---|---|
| Splash motion video | 1080 × 1920, ≤ 3 s, MP4 (H.264) ≤ 1.5 MB | `assets/brand/splash_motion.mp4` |
| Drawer illustration | 600 × 900 px, transparent PNG | `assets/brand/drawer_art.png` |
| Subject header art | 1080 × 480 px PNG per subject | `assets/subjects/<code>.png` |
| Practice page header | 1080 × 420 px PNG | `assets/brand/practice_header.png` |
| Flashcards page header | 1080 × 420 px PNG | `assets/brand/flashcards_header.png` |
| Deck product images | 600 × 800 px PNG (upload as the deck cover in the admin) | admin |
| Card templates | 1241 × 1754 px (A4 portrait), same margins as before | `assets/templates/<name>.png` |
