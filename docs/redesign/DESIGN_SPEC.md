# Plengo — Design spec v2 (colorful)

All sizes are in logical pixels (dp). The screens are designed at 390 × 844. The HTML files in `screens/` are the visual reference, and this document is the rule book.

---
## 1. Brand

- **Logo:** use `assets/brand/` as it is (color wordmark with a white "sticker" border on yellow; blue version on light backgrounds; white version in dark mode). Never redraw, recolor or mirror it.
- **Font:** MontserratArabic only. Weights: 400 body, 500 secondary/inputs, 600 labels and buttons, 700 titles and numbers.
- **Tone:** playful and encouraging, but not childish (teenagers and university students preparing for serious exams). Use short Arabic copy, and use the app's existing strings where they exist.
- **Digits:** Western (0–9). Emails, codes, URLs and math formulas are LTR-isolated inside RTL text.

## 2. Color system (each color has ONE job)

| Token | Base | Soft (background) | Ink (text on soft) | Role |
|---|---|---|---|---|
| yellow | `#FFD62C` | `#FFF4C2` | `#6B5200` | brand, celebration, active nav pill, exam countdown, "done" path node, brand CTA |
| blue | `#0074B4` | `#E3F1FA` | `#005E92` | **all primary buttons and links**, progress, current item |
| green | `#1FCD33` | `#E3F8E6` | `#157A22` | correct ✓, completed, daily-goal ring, "free" chip |
| red | `#E54E4E` (fill on dark text) / `#C63B3B` (fill with white text) | `#FDE8E8` | `#B42323` | wrong ✗, mistakes, locked, destructive |
| orange | `#F99A2C` | `#FEEEDB` | `#9A5205` | streak (flame), skipped, flagged in exam |
| pink | `#E3A4E8` | `#F7E6F9` | `#7B2F83` | my decks, teachers, decoration |

**Neutrals (light / dark):**

| Token | Light | Dark |
|---|---|---|
| background | `#FAF8F3` (warm off-white) | `#151515` |
| card | `#FFFFFF` | `#1F1F1F` |
| ink | `#1B1B1B` | `#F2F2F2` |
| mute (secondary text) | `#5E5A52` | `#B5B0A6` |
| line | `#ECE7DC` | `#2E2E2E` |
| skeleton / track | `#EFEAE0` | `#2A2A2A` |
| action | `#0074B4` | `#5CB8EE` (with ink `#1B1B1B` on it) |

**Rules**
- Text on a soft background always uses that color's **ink** (all pairs ≥ 4.5:1).
- White text is only allowed on blue `#0074B4` or red `#C63B3B`. Yellow, green, orange and pink fills always take dark text `#1B1B1B`.
- **Subject colors** are fixed per subject and reused everywhere that subject appears (Home cards, Subjects list, Subject header ring, Stats bars). If the backend provides a color, use it; otherwise map by subject id to one of the six.
- **Deck colors** (my decks): the six-color picker uses the six bases above.

## 3. Shape, spacing, elevation
- **Radii:** card 24 · hero 28 · list row 20 · button 18 · small button 14 · chip/pill 99 · option tile 18 · bottom sheet 28 (top corners) · icon tile 14.
- **Spacing:** screen padding 20 · gap between sections 16 · inside cards 16 (hero 20) · list gap 10.
- **Card shadow (light only):** `0 1 0 line` + `0 6 18 rgba(60,45,10,.05)`. In dark mode use a 1 px `line` border instead of a shadow.
- **3D buttons:** a 4 px solid bottom shadow in a darker shade (blue → `#005E92`, yellow → `#D9AF00`, green → `#15A126`, red → `#8E2626`). When pressed: move the button down 4 px and remove the shadow (≈100 ms).
- **Bottom sheet:** 28 top radius, scrim `rgba(20,20,20,.45)`, drag handle 40 × 5.

## 4. Components (build these first)

| Component | Spec |
|---|---|
| **Button** | Height 54 (small: 48). Variants: **primary** (action color + 3D), **brand** (yellow + 3D, for celebration and "continue" moments), **secondary** (card background, 2 px action border, action text), **ghost** (text only, action color), **disabled** (skeleton color, mute text, no shadow). Icon + label gap 8. |
| **Card** | See §3. **Hero** variant: blue fill, white text, decorative circles, yellow button inside. |
| **Chip** | Height 28, soft background + ink text, optional 14 px icon. |
| **Progress bar** | Height 10 (6 in compact headers), track = skeleton color, fill = the context color, **always with a text label** (e.g. "السؤال 7 من 20"). |
| **Progress ring** | Stroke 6–9, round caps, value text in the center. Used for the daily goal (green), subject completion (subject color or yellow on blue headers). |
| **Subject icon tile** | 40–48 square, radius 14, solid base fill with dark icon (blue/red use white icon). |
| **List row** | Min height 64, radius 20, icon tile + title (15/700) + caption (12/400 mute) + trailing chevron (mirrored) or chip. **Flat** variant for grouped lists (divider lines). |
| **Pill selector** | Height 44, radius 99. Selected: ink-black fill + white text (dark mode: yellow fill + dark text). Scrolls horizontally. Used for stage, subject filter, result filter and saved filter. |
| **Segmented control** | Track = skeleton color, 4 padding. Selected segment = card color + light shadow + bold. |
| **Radio row** | Min height 60, 2 px border. Selected = blue border + blue-soft background + filled dot. |
| **Answer option** | Min height 62, radius 18, 2 px border, 3 px bottom shadow, letter badge (أ ب ج د) at the start. **States:** normal · selected (blue border, blue-soft background, blue badge) · correct (green border, green-soft background, green badge, tag "✓ صحيحة") · wrong (red border, red-soft background, red badge, tag "✗ إجابتك") · dimmed (60% opacity) after checking. |
| **Feedback panel** | Full-width bottom panel, top radius 28. Correct: green-soft background, 44 green circle with ✓, title «أحسنت!», explanation, green button «متابعة». Wrong: red-soft background, red circle with ✗, «ليست الإجابة الصحيحة», the correct answer line, explanation, «أضفناه إلى مراجعة الأخطاء», red button «فهمت، متابعة». A report-flag icon button sits inside the panel. |
| **Bottom nav** | 5 tabs, icon 22 + label 11. Active = yellow pill (58 × 32) behind the icon + bold label + `aria-current`. Background = card color with a top border. |
| **Side rail (≥600 dp)** | 240 wide, blue logo on top, rows of 52 height. Active row = yellow fill. |
| **Empty state** | 120 circle (soft color) with a large icon, title 18/700, one line of text, optional secondary button. |
| **Error state** | Same as empty, plus a primary «إعادة المحاولة» button and an offline escape link. |
| **Skeleton** | Blocks in the skeleton color that mirror the real layout, plus a hidden «جارٍ التحميل…» status for screen readers. |
| **Confetti dots** | 3–5 small circles (10–28) in logo colors around celebration icons. Decorative only (exclude from semantics). |

## 5. Navigation
- **Tabs:** الرئيسية · المواد · المراجعة · المحفوظات · حسابي.
- **Back:** a mirrored arrow in a 48 × 48 soft square at the start of the app bar.
- **Close (✕):** used only in full-screen flows (question, exam, flashcard review, results).
- **Leaving practice or an exam:** ✕ opens a confirmation sheet; it never discards silently.
  - Practice: «تقدّمك محفوظ», with «واصل التدريب» (primary) and «خروج».
  - Exam: «الخروج من الامتحان؟ إجاباتك محفوظة…», with «واصل الامتحان» and «خروج».

## 6. Screens (file → behaviour)

### Entry
- **V-Splash:** full yellow, color logo centered (240 wide), small dark loader.
- **V-Onboarding:** 3 pages («رحلتك التعليمية أسهل مع Plengo» / «تعلّم بطريقتك» / «حقّق أهدافك»).
  - Each page has a big icon in a colored circle (blue → pink → green) with a soft ring and confetti dots.
  - Progress dots: the active one is a 28-wide blue pill.
  - «تخطي» is always visible.
  - Last page: «ابدأ الآن» (yellow) and «لدي حساب — تسجيل الدخول».
- **V-Login / V-LoginError:**
  - Yellow top band with the logo and decorative circles; the form sits on an off-white panel that overlaps it with a 28 radius.
  - The error appears under the field: red border, red-soft background, alert icon and recovery text.
- **V-Register:**
  - Fields: name, email (LTR), password (hint «8 أحرف على الأقل»), confirm.
  - Stage pills: التاسع / البكالوريا / الجامعة. University reveals optional university → faculty → year in a blue-soft box.
  - Terms line, then the primary button.
- **V-Verify:** mail icon in a blue-soft circle, the email in LTR, «تعديل البريد», 6 LTR digit boxes (active box has a blue border), a 60 s resend countdown, then «تحقق» → Goal step (flag) or Home.
- **V-Goal (new, flag `newDailyGoalStep`):** goal radio list 10 خفيف ~5 د · 20 عادي ~10 د · 30 جاد ~15 د · 50 مكثّف ~25 د · 100 تحدٍّ ~50 د, a review-reminder switch (default ON, time shown in Damascus time), «متابعة», and «تخطي».

### Home (`V-Home`; dark: `V-HomeDark`; large text: `V-HomeLarge`; offline: `V-Offline`; loading: `V-Loading`)

Order (flag `homeOrderV2`):
1. **Header:** avatar, «مرحباً، [الاسم]», «واصل رحلتك التعليمية», and a bell with a red unread badge.
2. **Continue hero (blue):** «تابع من حيث توقفت», the title, subject · activity, a yellow progress bar with label, and a yellow «تابع» button. It opens the resume item, whatever type it is (quiz / cards / questions).
3. **Today card:**
   - flame chip «N أيام متتالية» (orange)
   - green goal ring «12/20», «هدف اليوم: 12 من 20», ghost «تعديل الهدف» (opens the goal sheet with the same labelled list as V-Goal)
   - primary «مراجعة البطاقات المستحقة (N)»
   - a red-soft row «لديك N أخطاء للمراجعة», **only if the mistakes bank is not empty**.
4. **Exam countdown:** yellow card, clock icon, «باقي N يوماً على …».
5. **Banners:** horizontal carousel with dots; a tap opens the banner's action.
6. **«موادّي ومساراتي»:** horizontal cards in the subject's soft color, with an icon tile, a ring and the unit progress caption.
7. **«محتوى مجاني»:** horizontal cards with a colored image area and a «مجاني» chip.
8. **«مدرسون أتابعهم»:** 64 circular avatars with a colored ring.

Offline: a dark banner at the top («أنت غير متصل بالإنترنت» + links المراجعة / المحتوى المحمّل). Continue stays usable if its content is downloaded.

### Learning
- **V-Notifications:** list of rows, each with an icon tile colored by type:
  - new content = blue · review reminder = yellow · teacher update = pink · report handled = green · offer = orange · announcement = red
  - unread = bold title + blue dot + warm background
  - «تعليم الكل كمقروء» in the app bar; a link to notification settings at the bottom.
- **V-Subjects:** stage pills (التاسع / البكالوريا / الجامعة; university shows three compact selects), subject rows with a solid colored icon tile, the «المدرسون» button in the app bar, locked subjects with a red «مقفل» chip, and a yellow «لديك كود تفعيل؟» row (hidden on the no-codes iPhone build).
- **V-Subject (learning path, flag `learningPath`):**
  1. **Blue header** with a large title, counts «available/total» for questions · tests · cards, a yellow completion ring, and download + back buttons.
  2. **Access chip** (green): «لديك وصول دائم» / «حتى …» / «متاح مجاناً ضمن …». If there is no access: the locked box with «إدخال كود التفعيل».
  3. **Shortcut row** of 4 (الاختبارات / تدريب عشوائي / البطاقات / بنك الأسئلة) with counts «N · k مجاني».
  4. **Completed units** collapse into one green row.
  5. **The current unit:**
     - a blue banner with title, lessons count and % plus a unit-download button
     - then a **zig-zag path** of 76 dp circular nodes with 6 dp bottom shadows, each with a text label under it. Node states: done = yellow ✓ · current = blue ▶ (larger, with an «ابدأ هنا» bubble) · upcoming = grey book · unit quiz = orange trophy at the end.
     - tapping a node opens an anchored card with the title, meta, a primary action («تابع الدرس» / «ابدأ الدرس» / «تدرّب مجدداً» / «ابدأ اختبار الوحدة») and «عرض الدرس بالتفصيل».
     - **all unlocked lessons stay tappable** (never force linear order).
  6. **Locked units:** a single red-soft row that leads to redeem.
  7. Then «دروس عامة» and «مسارات المدرسين» (rows with a «متاح» / «مقفل» chip).

  Flag off: the units accordion (number or ✓ badge, lessons count, %, bar, unit download, lessons list with «التالي»).
- **V-Lesson:** three entries:
  - **lesson questions:** blue-soft card with progress and «تابع التدريب» (this is the primary)
  - **flashcards:** pink row
  - **quizzes:** orange row, with the best score.
- **V-Quiz:**
  - chips «امتحان تجريبي» and «أفضل نتيجة»
  - three tiles: duration (blue) · pass mark (green) · attempts used of allowed (orange)
  - a yellow «متابعة الاختبار» row, **only when an attempt is unfinished**
  - mode radio cards: «وضع التدريب» (instant correction) / «وضع الامتحان» (no correction until the end)
  - «محاولاتي» (score chip + date)
  - the bottom button label follows the mode.
- **V-Question (practice):**
  - **App bar:** ✕ (exit sheet), green progress bar with «السؤال 3 من 10 · صحيحة 2 من 3», report flag (opens the report sheet: 5 reasons + optional note + «إرسال البلاغ»), save/bookmark.
  - **Body:** question-type chip, question text 21/700 (formulas LTR), option tiles. Written-answer questions use a large «إجابتك» input instead of options.
  - **Bottom:** disabled «اختر إجابة», then «تحقق», then the feedback panel (§4) with «متابعة» → next question, or → Results on the last one.
  - **After a correct answer:** an orange chip «N إجابات صحيحة متتالية!» when the in-session streak is ≥ 3 (the string already exists).
- **V-Exam:**
  - **App bar:** ✕ (exit sheet), «السؤال 4 من 20 · أجبت عن 3», and a timer chip (blue-soft; **turns red with a pulse in the last 60 s**).
  - **Question grid toggle:** a 5-column grid of 48 dp squares — answered = blue fill · unanswered = outline · flagged = orange-soft + ⚑ · current = yellow + dark border — with a text legend.
  - «علّم للمراجعة» toggles to a yellow «معلّم للمراجعة».
  - «السابق | التالي».
  - Ghost «إنهاء الامتحان» opens **review-before-finish**: counts of unanswered (orange-soft) and flagged (yellow-soft), «عودة إلى الأسئلة», «إنهاء الامتحان الآن».
  - Offline note: «تُحفظ إجاباتك على الجهاز وتُرسل لاحقاً».
- **V-Results:**
  - **Pass:** trophy in a yellow circle with a soft ring and confetti, «أنهيت الدرس!», «16 من 20 · ناجح — علامة النجاح 60%».
  - **Fail:** a target icon + «واصل التدريب» + «لم تبلغ علامة النجاح».
  - **4 stat tiles** (colored label strip on top, icon + number below): صحيحة green · خاطئة red · متروكة orange · الوقت blue.
  - The daily-goal row, then «أعد الأخطاء فقط (N)» + «أعد الاختبار».
  - Filter pills الكل / الخاطئة / المتروكة / المعلّمة, then the per-question review (state chip, your answer, correct answer, explanation).
  - Bottom «متابعة» → streak screen (flag `newStreakMoment`, once per day after the first finished activity) → Home.
- **V-Streak (new):** a big orange flame in an orange-soft circle with confetti, the number 64/700, «أيام متتالية!», one encouraging line, a week row (filled orange circles with ✓ for studied days, today with a double ring) and a yellow «متابعة». Copy must never threaten or shame.

### Flashcards (keep the CURRENT app layout; these are refinements)
- **V-FcDecks (deck list):** rows with a deck-color strip at the start edge, an icon tile, name, «N بطاقة · مجانية», a trailing due chip («12 مستحقة» yellow / «لا شيء مستحق» green ✓) or «مقفلة» (red, lock). A top yellow-soft summary «كل البطاقات المستحقة: N» with «ابدأ المراجعة».
- **V-FcDeck (deck page):**
  - a deck thumbnail, subject · unit caption, name, chips (count, free), description
  - a card with «مستحقة اليوم: N · حوالي M دقائق» and chips جديدة / قيد التعلم / مراجعة
  - buttons «مراجعة» (primary, wider) and «تصفح» (secondary)
  - a download card with all offline states (§7)
  - when nothing is due: «البطاقة التالية: …».
- **V-FcBrowse:**
  - «5 / 131» with a thin progress bar
  - zoom button for image cards
  - the official card image (vertical, or square when the asset is square), framed in the deck color with the logo at the foot
  - **3D flip on tap** (rotateY 180°, ≈500 ms ease-out) and swipe left/right to navigate
  - «السابق | اقلب البطاقة | التالي»
  - «+ أضف إلى بطاقاتي», which toggles to «✓ أُضيفت البطاقة إلى مجموعتك».
- **V-Flashcards (SRS review):**
  - **Top:** ✕ · counts جديدة (blue) · تعلّم (orange) · مراجعة (green), where the bucket of the current card is underlined and the counts update live · overflow menu (save, report).
  - A thin session progress bar.
  - **The card:** 3D flip with the hint «اضغط على البطاقة لعرض الإجابة».
  - **Bottom slot (fixed height so nothing jumps):** «اقلب البطاقة» before the flip; after the flip, three rating buttons with the next interval under each label:
    - «مرة أخرى» red `#C63B3B` with white text
    - «جيد» yellow
    - «سهل» green
  - «تراجع» appears only after the first rating.
  - **Done:** trophy, «أنهيت مراجعة اليوم», «البطاقة التالية: …», a rating summary chips row, «العودة إلى الرئيسية».

### Review / Saved / Account
- **V-Review:**
  - subject pills
  - a yellow hero «كل البطاقات المستحقة» with a big number, the new/learning/review chips and «ابدأ المراجعة»
  - three tiles: بطاقاتي (pink) · مراجعة الأخطاء (red) · إحصائياتي (blue)
  - a «تدريب عشوائي» row (orange). Its setup: units/lessons, types, count 5–50, practice/exam.
  - Empty state: «لا توجد بطاقات مستحقة الآن» + the next due time.
- **V-Mistakes:**
  - segmented «نشطة | متقنة», filter pills for subject / unit / type
  - one explanatory line («يصبح السؤال متقناً بعد…», using the real rule)
  - cards with «أخطأت N مرات · صحيحة متتالية: k» and «تدرّب»
  - a sticky «اختبر أخطائي».
- **V-Stats:**
  - number tiles, one per color: answered, accuracy, tests completed, study days, streak, average time, active mistakes
  - weekly accuracy bars (12 weeks, the current week highlighted)
  - per-subject bars, per-type accuracy, weakest units with «تدرّب», most-missed questions
  - due-in-7-days bars and the daily reviews chart.
  - Every chart has a text summary for screen readers.
- **V-MyDecks:** deck rows with a color strip; the create form (name + six-color picker); inside a deck: the card list, «مراجعة», «تصفح», «بطاقة جديدة». The card editor has front/back, each with text and/or an image (gallery/camera); restyle the existing editor.
- **V-Saved:** pills الكل / الأسئلة / المجموعات / البطاقات / بطاقاتي, rows with a type-colored icon tile + type · subject, and the empty state «احفظ الأسئلة والبطاقات لتعود إليها هنا».
- **V-Account:**
  - **Header:** yellow-soft card with avatar (camera button to change it), name, email in LTR.
  - **Appearance card:** segmented تلقائي / فاتح / داكن, and segmented font size (labels shown at their own size).
  - **Grouped flat lists:**
    - صلاحيات الوصول, إدخال كود التفعيل, المحتوى المحمّل, الإشعارات والهدف اليومي, المرحلة التعليمية, المدرسون الذين أتابعهم, الأجهزة المتصلة
    - legal links
  - **A separate card:** تسجيل الخروج and حذف الحساب, in red.
- **V-Redeem:** a red-soft «هذا المحتوى يحتاج إلى تفعيل» row, an illustration of a yellow activation card, one big centered LTR code field `XXXX-XXXX-XX` with letter-spacing, «تفعيل», and a ghost «جرّب الدروس المجانية أولاً».
- **V-RedeemSuccess:** a green check circle with confetti, «تم التفعيل بنجاح», the access date, an optional download offer (mobile only), and a yellow «الذهاب إلى المحتوى».

### States
- **V-ErrorRetry:** generic error page.
- **V-Loading:** skeleton.
- **Empty states:** follow §4.
- **Locked content:** always a lock icon + text, never color only.

### Wide screens
- **V-Web:** side rail + content capped at 720. The Continue and Today cards sit side by side.

## 7. Offline download control (one component, all states)
| State | Display |
|---|---|
| not downloaded | «الحجم التقريبي: N ميغابايت» + «تحميل» |
| downloading | progress bar + % + pause + cancel |
| waiting for Wi‑Fi | «بانتظار Wi‑Fi» + «تحميل عبر البيانات» |
| paused / failed | «متابعة» (+ the error text on failure) |
| update available | «تحديث متاح» + «تحديث» |
| complete | «متاح دون اتصال» chip (blue, download icon) + delete |

Mobile only; hide it on web.

## 8. Motion
Keep motion short and purposeful:
- button press: 100 ms
- card flip: 500 ms
- sheet slide-up: 250 ms
- feedback panel slide-up: 200 ms
- progress bar fill: 300 ms
- celebration screens: confetti dots scale in, ≤ 600 ms, once

Respect "reduce motion" (disable the flip rotation and use a crossfade instead).

## 9. Feature checklist: every item must still be reachable
- **Auth:** login · register (with stage) · verify email · forgot/reset password · force update · logout · delete account (with password).
- **Home:** resume · goal + goal edit · streak · due cards · mistakes shortcut · exam countdown · banners (with their actions) · my subjects & tracks · free content · followed teachers · notifications (list, mark all read, settings: learning toggle, offers toggle, reminder time 6:00–23:00, daily goal).
- **Content:** stage / university / faculty / year filters · subjects · subject page (access status, counts, tests, random practice, flashcards, question bank, offline download, units, lessons, general lessons, teacher tracks) · teachers list · teacher page (follow / unfollow + note) · track page · lesson page.
- **Questions:** question list (free badge, locked) · practice with check/explanation · written answers · report sheet · bookmark.
- **Quizzes:** list (modes, mock badge, best score) · quiz page (duration, pass mark, attempts, resume) · practice/exam modes · exam timer, flag, grid, review-before-finish, offline save · results (filters, per-question review, retry wrong only, retry).
- **Flashcards:** deck list · deck page · browse (flip, prev/next, add to my cards) · SRS review (counts, flip, 3 ratings with intervals, undo, done screen).
- **Review:** due cards by subject · mistakes bank (active/mastered, filters, test my mistakes) · stats (all charts) · my decks (create with color, card editor with images) · random practice setup.
- **Saved:** all filters + empty state.
- **Account:** avatar change · appearance (theme + font size) · access list (permanent / until / active / expired / revoked) · redeem code + success (+ download offer) · offline content (Wi‑Fi only, auto update, storage used, list + delete) · notifications & goal · stage · followed teachers · connected devices (this device badge, end other sessions) · privacy · terms · licenses.
