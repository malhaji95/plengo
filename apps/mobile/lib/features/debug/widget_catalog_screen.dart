import 'package:flutter/material.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';

/// Debug-only catalogue of the redesign components (`/debug/catalog`, registered only in debug builds).
/// Pick light or dark and the app's three font sizes; on wide screens light and dark sit side by side.
class WidgetCatalogScreen extends StatefulWidget {
  const WidgetCatalogScreen({super.key});

  @override
  State<WidgetCatalogScreen> createState() => _WidgetCatalogScreenState();
}

class _WidgetCatalogScreenState extends State<WidgetCatalogScreen> {
  Brightness? _only = Brightness.light;
  int _fontStep = 1;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final both = wide && _only == null;
    Widget pane(Brightness b) => _CatalogPane(brightness: b, fontStep: _fontStep);
    return Scaffold(
      appBar: AppBar(
        leading: const PlengoBackButton(),
        leadingWidth: kPlengoLeadingWidth,
        title: const Text('مكوّنات التصميم'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
            child: Column(
              children: [
                SegmentedControl<Brightness?>(
                  segments: [
                    const PlengoOption(Brightness.light, 'فاتح'),
                    const PlengoOption(Brightness.dark, 'داكن'),
                    if (wide) const PlengoOption(null, 'كلاهما'),
                  ],
                  selected: _only,
                  onChanged: (v) => setState(() => _only = v),
                ),
                const SizedBox(height: 8),
                SegmentedControl<int>(
                  segments: const [PlengoOption(0, 'صغير'), PlengoOption(1, 'عادي'), PlengoOption(2, 'كبير')],
                  selected: _fontStep,
                  onChanged: (v) => setState(() => _fontStep = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: both
                ? Row(
                    children: [
                      Expanded(child: pane(Brightness.light)),
                      Expanded(child: pane(Brightness.dark)),
                    ],
                  )
                : pane(_only ?? Brightness.light),
          ),
        ],
      ),
    );
  }
}

class _CatalogPane extends StatefulWidget {
  const _CatalogPane({required this.brightness, required this.fontStep});

  final Brightness brightness;
  final int fontStep;

  @override
  State<_CatalogPane> createState() => _CatalogPaneState();
}

class _CatalogPaneState extends State<_CatalogPane> {
  String _pill = 'bac';
  int _segment = 0;
  int _radio = 20;
  int _option = -1;
  bool _checked = false;
  int _nav = 0;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light();
    final scale = AppearanceSettings.fontScales[widget.fontStep];
    final mq = MediaQuery.of(context);
    return Theme(
      data: theme,
      child: MediaQuery(
        data: mq.copyWith(textScaler: TextScaler.linear(mq.textScaler.scale(1) * scale)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Material(
            color: theme.scaffoldBackgroundColor,
            child: Builder(builder: _content),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final s = context.surface;
    const correctIndex = 0;
    AnswerState stateOf(int i) {
      if (!_checked) return i == _option ? AnswerState.selected : AnswerState.normal;
      if (i == correctIndex) return AnswerState.correct;
      if (i == _option) return AnswerState.wrong;
      return AnswerState.dimmed;
    }

    Widget title(String t) => SectionHeader(t);
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 40),
      children: [
        title('الألوان'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final h in PlengoColors.all) PlengoChip(label: h.name, hue: h, icon: Icons.circle)],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final id in const ['math', 'physics', 'chem', 'arabic', 'english', 'bio'])
              SubjectIconTile.forSubject(id, icon: Icons.menu_book_rounded),
          ],
        ),
        title('الأزرار'),
        PlengoButton(label: 'زر أساسي', icon: Icons.play_arrow_rounded, onPressed: () {}),
        const SizedBox(height: 10),
        PlengoButton(label: 'زر الهوية', variant: PlengoButtonVariant.brand, onPressed: () {}),
        const SizedBox(height: 10),
        PlengoButton(label: 'زر ثانوي', variant: PlengoButtonVariant.secondary, onPressed: () {}),
        const SizedBox(height: 10),
        PlengoButton(label: 'زر نصي', variant: PlengoButtonVariant.ghost, onPressed: () {}),
        const SizedBox(height: 10),
        PlengoButton(label: 'مرة أخرى', variant: PlengoButtonVariant.danger, onPressed: () {}),
        const SizedBox(height: 10),
        PlengoButton(label: 'سهل', variant: PlengoButtonVariant.success, onPressed: () {}),
        const SizedBox(height: 10),
        const PlengoButton(label: 'زر معطّل', onPressed: null),
        const SizedBox(height: 10),
        PlengoButton(label: 'إرسال', busy: _busy, onPressed: () => setState(() => _busy = !_busy)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PlengoButton(label: 'صغير', size: PlengoButtonSize.small, onPressed: () {}),
            PlengoButton(
              label: 'صغير ثانوي',
              size: PlengoButtonSize.small,
              variant: PlengoButtonVariant.secondary,
              onPressed: () {},
            ),
            const PlengoBackButton(),
            const PlengoCloseButton(),
            PlengoIconButton(icon: Icons.notifications_none_rounded, tooltip: 'الإشعارات', badge: 3, onPressed: () {}),
          ],
        ),
        title('البطاقات'),
        PlengoHeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('تابع من حيث توقفت', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('الوحدة 3: المشتقات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              PlengoProgressBar(
                value: 0.35,
                label: 'السؤال 7 من 20',
                color: PlengoColors.yellow.base,
                trackColor: Colors.white.withValues(alpha: 0.3),
                labelColor: Colors.white,
              ),
              const SizedBox(height: 12),
              PlengoButton(
                label: 'تابع',
                icon: Icons.play_arrow_rounded,
                variant: PlengoButtonVariant.brand,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PlengoCard(
          child: Row(
            children: [
              const ProgressRing(value: 0.6, label: '12/20', size: 76),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('هدف اليوم: 12 من 20', style: PlengoType.rowTitle.copyWith(color: s.ink)),
                    Text('بطاقات وإجابات', style: PlengoType.caption.copyWith(color: s.mute)),
                    const SizedBox(height: 6),
                    const PlengoChip(
                      label: '5 أيام متتالية',
                      hue: PlengoColors.orange,
                      icon: Icons.local_fire_department_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        title('الشارات'),
        const Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            PlengoChip(label: 'مجاني', hue: PlengoColors.green),
            PlengoChip(label: 'مقفل', hue: PlengoColors.red, icon: Icons.lock_rounded),
            PlengoChip(label: 'متاح دون اتصال', icon: Icons.download_done_rounded),
            PlengoChip(label: 'امتحان تجريبي', hue: PlengoColors.pink),
            PlengoChip(label: '12 مستحقة', hue: PlengoColors.yellow),
          ],
        ),
        title('التقدّم'),
        const PlengoProgressBar(value: 0.3, label: 'السؤال 3 من 10'),
        const SizedBox(height: 10),
        PlengoProgressBar(
          value: 0.3,
          compact: true,
          labelBelow: true,
          color: PlengoColors.green.base,
          label: 'السؤال 3 من 10 · صحيحة 2 من 3',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ProgressRing(value: 0.42, label: '42%', size: 46, color: PlengoColors.blue.base),
            const SizedBox(width: 12),
            const ProgressRing(value: 1, label: '20/20'),
          ],
        ),
        title('القوائم'),
        ListRow(
          icon: Icons.calculate_rounded,
          hue: subjectHue('math'),
          title: 'الرياضيات',
          caption: 'الوحدة 3 من 6',
          onTap: () {},
        ),
        const SizedBox(height: PlengoSpace.listGap),
        ListRow(
          icon: Icons.science_rounded,
          hue: PlengoColors.red,
          title: 'الكيمياء',
          caption: '24 درساً',
          trailing: const PlengoChip(label: 'مقفل', hue: PlengoColors.red, icon: Icons.lock_rounded),
          onTap: () {},
        ),
        const SizedBox(height: PlengoSpace.listGap),
        ListRow(
          icon: Icons.error_outline_rounded,
          hue: PlengoColors.red,
          title: 'لديك 9 أخطاء للمراجعة',
          background: PlengoColors.red.soft,
          onTap: () {},
        ),
        const SizedBox(height: PlengoSpace.listGap),
        PlengoCard(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              ListRow(flat: true, icon: Icons.key_rounded, title: 'صلاحيات الوصول', onTap: () {}),
              ListRow(
                flat: true,
                icon: Icons.download_rounded,
                hue: PlengoColors.green,
                title: 'المحتوى المحمّل',
                onTap: () {},
              ),
              ListRow(
                flat: true,
                showDivider: false,
                icon: Icons.notifications_rounded,
                hue: PlengoColors.yellow,
                title: 'الإشعارات والهدف اليومي',
                onTap: () {},
              ),
            ],
          ),
        ),
        title('الاختيار'),
        PillSelector<String>(
          padding: EdgeInsets.zero,
          options: const [
            PlengoOption('9', 'التاسع'),
            PlengoOption('bac', 'البكالوريا'),
            PlengoOption('uni', 'الجامعة'),
          ],
          selected: _pill,
          onSelected: (v) => setState(() => _pill = v),
        ),
        const SizedBox(height: 12),
        SegmentedControl<int>(
          segments: const [PlengoOption(0, 'نشطة'), PlengoOption(1, 'متقنة')],
          selected: _segment,
          onChanged: (v) => setState(() => _segment = v),
        ),
        const SizedBox(height: 12),
        for (final (n, label, mins) in const [(10, 'خفيف', '~5 د'), (20, 'عادي', '~10 د'), (30, 'جاد', '~15 د')]) ...[
          RadioRow(
            title: label,
            selected: _radio == n,
            trailing: Text('$n عنصراً · $mins'),
            onTap: () => setState(() => _radio = n),
          ),
          const SizedBox(height: 6),
        ],
        title('خيارات الإجابة'),
        for (final (i, t) in const ['6x', '3x', '6x²', 'x³'].indexed) ...[
          AnswerOption(
            index: i,
            text: t,
            ltr: true,
            state: stateOf(i),
            onTap: _checked ? null : () => setState(() => _option = i),
          ),
          const SizedBox(height: 7),
        ],
        Row(
          children: [
            Expanded(
              child: PlengoButton(
                label: _checked ? 'إعادة' : 'تحقق',
                onPressed: _option < 0 ? null : () => setState(() => _checked = !_checked),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FeedbackPanel(
          correct: true,
          onContinue: () {},
          onReport: () {},
          explanation: const Text('نضرب الأس في المعامل ثم ننقص الأس واحداً.'),
        ),
        const SizedBox(height: 12),
        FeedbackPanel(
          correct: false,
          onContinue: () {},
          onReport: () {},
          correctAnswer: const Text('6x', textDirection: TextDirection.ltr),
          explanation: const Text('نضرب الأس في المعامل ثم ننقص الأس واحداً.'),
          note: FeedbackPanel.mistakesNote,
        ),
        title('النوافذ السفلية'),
        PlengoButton(
          label: 'نافذة تأكيد',
          variant: PlengoButtonVariant.secondary,
          onPressed: () => showConfirmSheet(
            context,
            icon: Icons.save_rounded,
            title: 'تقدّمك محفوظ',
            message: 'يمكنك المتابعة من السؤال 3 في أي وقت من الرئيسية.',
            primaryLabel: 'واصل التدريب',
            secondaryLabel: 'خروج',
          ),
        ),
        title('التنقل'),
        PlengoNavBar(
          destinations: const [
            PlengoNavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'الرئيسية'),
            PlengoNavDestination(
              icon: Icons.menu_book_outlined,
              selectedIcon: Icons.menu_book_rounded,
              label: 'المواد',
            ),
            PlengoNavDestination(icon: Icons.style_outlined, selectedIcon: Icons.style_rounded, label: 'المراجعة'),
            PlengoNavDestination(
              icon: Icons.bookmark_border_rounded,
              selectedIcon: Icons.bookmark_rounded,
              label: 'المحفوظات',
            ),
            PlengoNavDestination(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'حسابي',
            ),
          ],
          selectedIndex: _nav,
          onSelected: (i) => setState(() => _nav = i),
        ),
        title('الحالات'),
        const PlengoEmptyState(
          icon: Icons.bookmark_border_rounded,
          title: 'لا توجد عناصر محفوظة',
          message: 'احفظ الأسئلة والبطاقات لتعود إليها هنا',
          actionLabel: 'تصفح المواد',
          onAction: _noop,
        ),
        PlengoErrorState(
          title: 'تعذّر تحميل المواد',
          message: 'تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت ثم أعد المحاولة.',
          onRetry: () {},
          offlineLabel: 'راجع المحتوى المحمّل',
          onOffline: () {},
        ),
        const EmptyState('حالة فارغة قديمة', hint: 'عبر EmptyState'),
        const PlengoLoadingSkeleton(padding: EdgeInsets.zero),
        title('زينة'),
        const Center(
          child: ConfettiDots(
            child: StateIllustration(icon: Icons.emoji_events_rounded, hue: PlengoColors.yellow, size: 110),
          ),
        ),
      ],
    );
  }
}

void _noop() {}
