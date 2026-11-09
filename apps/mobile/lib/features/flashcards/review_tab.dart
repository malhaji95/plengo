import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/flashcard_repository.dart';
import '../../core/srs/scheduler.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/responsive.dart';
import '../home/home_providers.dart';
import '../my_decks/my_decks_providers.dart';
import 'decks_screen.dart';
import 'flashcard_providers.dart';
import 'flashcard_ui.dart';

final dueCardsProvider = FutureProvider.autoDispose<DueCards>((ref) async {
  await ref.read(srsSyncProvider).syncNow();
  return ref.watch(flashcardRepositoryProvider).due();
});

/// When the next reviewed card on this device becomes due (the empty state's «البطاقة التالية»).
final nextLocalDueProvider = FutureProvider.autoDispose<int?>((ref) async {
  final now = ref.read(clockProvider)();
  final states = await ref.read(srsStoreProvider).dueStates(now + 400 * Srs.day);
  final upcoming = [
    for (final s in states.values)
      if (s.dueAt > now) s.dueAt,
  ]..sort();
  return upcoming.firstOrNull;
});

/// The Review tab (المراجعة): every due card across accessible decks, optionally one subject
/// ("كل البطاقات المستحقة", spec §13.2), plus the mistake bank and statistics (§16). Redesign: V-Review.
class ReviewTab extends ConsumerStatefulWidget {
  const ReviewTab({super.key});

  @override
  ConsumerState<ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends ConsumerState<ReviewTab> {
  String? _subjectId;

  Future<void> _start() async {
    await context.push(
      Uri(path: Routes.dueStudy, queryParameters: _subjectId == null ? null : {'subjectId': _subjectId}).toString(),
    );
    ref.invalidate(dueCardsProvider);
    ref.invalidate(nextLocalDueProvider);
  }

  @override
  Widget build(BuildContext context) {
    final due = ref.watch(dueCardsProvider);
    // The links work offline (student decks, §13.9); only the due list needs the server.
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, titleSpacing: PlengoSpace.screen, title: const Text('المراجعة')),
      body: ContentWidth(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(dueCardsProvider.future),
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 0, 28),
            children: [
              AsyncView(
                value: due,
                onRetry: () => ref.invalidate(dueCardsProvider),
                data: (d) {
                  final subjects = <String, String>{for (final c in d.cards) c.subjectId: c.subjectNameAr};
                  if (_subjectId != null && !subjects.containsKey(_subjectId)) _subjectId = null;
                  final cards = d.cards.where((c) => _subjectId == null || c.subjectId == _subjectId);
                  // The student's own cards count in "كل المواد" (their decks have no required subject).
                  final states = [
                    for (final c in cards) c.state,
                    if (_subjectId == null)
                      for (final c in d.userCards) c.state,
                  ];
                  final buckets = {for (final b in SrsBucket.values) b: 0};
                  for (final st in states) {
                    final b = SrsBucket.of(FlashcardRepository.cardStateOf(st).state);
                    buckets[b] = buckets[b]! + 1;
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (subjects.length > 1) ...[
                        PillSelector<String?>(
                          options: [
                            const PlengoOption(null, 'كل المواد'),
                            for (final MapEntry(key: id, value: name) in subjects.entries) PlengoOption(id, name),
                          ],
                          selected: _subjectId,
                          onSelected: (id) => setState(() => _subjectId = id),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: PlengoSpace.screen),
                        child: states.isEmpty
                            ? const _NothingDue()
                            : _DueHero(
                                count: states.length,
                                fresh: buckets[SrsBucket.fresh]!,
                                learning: buckets[SrsBucket.learning]!,
                                review: buckets[SrsBucket.review]!,
                                onStart: _start,
                              ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: PlengoSpace.screen),
                child: _LearningLinks(
                  subjectId: _subjectId,
                  dueSubjects: {for (final c in due.value?.cards ?? const <DueCard>[]) c.subjectId: c.subjectNameAr},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The yellow hero: the big due number, the time it takes, the three buckets and «ابدأ المراجعة».
class _DueHero extends StatelessWidget {
  const _DueHero({
    required this.count,
    required this.fresh,
    required this.learning,
    required this.review,
    required this.onStart,
  });

  final int count;
  final int fresh;
  final int learning;
  final int review;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final yellow = PlengoColors.yellow;
    Widget blob(double size, Color color) => ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(PlengoRadius.hero),
      child: ColoredBox(
        color: yellow.base,
        child: Stack(
          children: [
            PositionedDirectional(top: -40, end: -40, child: blob(140, const Color(0xFFFFE266))),
            PositionedDirectional(top: 24, end: 34, child: blob(22, PlengoColors.red.base)),
            PositionedDirectional(top: 60, end: 70, child: blob(14, PlengoColors.blue.base)),
            Padding(
              padding: const EdgeInsets.all(PlengoSpace.heroPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    label: 'كل البطاقات المستحقة: ${cardCountLabel(count)}، ${studyTimeLabel(count)}',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'كل البطاقات المستحقة',
                          style: PlengoType.chip.copyWith(fontSize: 13, color: PlengoColors.ink),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: 8,
                          children: [
                            Text(
                              '$count',
                              style: PlengoType.display.copyWith(fontSize: 44, height: 1.1, color: PlengoColors.ink),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '${cardNoun(count)} · ${studyTimeLabel(count)}',
                                style: PlengoType.sub.copyWith(fontWeight: FontWeight.w600, color: PlengoColors.ink),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  BucketChips(fresh: fresh, learning: learning, review: review, learningLabel: 'تعلّم'),
                  const SizedBox(height: 14),
                  PlengoButton(label: 'ابدأ المراجعة', icon: Icons.psychology_outlined, onPressed: onStart),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «لا توجد بطاقات مستحقة الآن» with when the next card is due (from the device's SRS states).
class _NothingDue extends ConsumerWidget {
  const _NothingDue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextLocalDueProvider).value;
    return PlengoCard(
      padding: EdgeInsets.zero,
      child: PlengoEmptyState(
        title: 'لا توجد بطاقات مستحقة الآن',
        message: next == null ? null : 'البطاقة التالية: ${nextDueLabel(next, ref.read(clockProvider)())}',
        icon: Icons.check_circle_outline_rounded,
        hue: PlengoColors.green,
      ),
    );
  }
}

/// بطاقاتي, مراجعة الأخطاء, إحصائياتي and تدريب عشوائي live under the Review tab.
class _LearningLinks extends ConsumerWidget {
  const _LearningLinks({required this.subjectId, required this.dueSubjects});

  /// The subject picked in the pills, if any.
  final String? subjectId;

  /// Subjects that have due cards (candidates for random practice).
  final Map<String, String> dueSubjects;

  Future<void> _randomPractice(BuildContext context, WidgetRef ref) async {
    final home = ref.exists(homeProvider) ? ref.read(homeProvider).value : null;
    final subjects = <String, String>{
      ...dueSubjects,
      for (final f in home?.freeSubjects ?? const <FreeSubject>[]) f.subjectId: f.nameAr,
    };
    String? id = subjectId;
    if (id == null && subjects.length == 1) id = subjects.keys.single;
    if (id == null && subjects.isNotEmpty) {
      id = await showPlengoSheet<String>(
        context: context,
        title: 'تدريب عشوائي في أي مادة؟',
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, MapEntry(key: sid, value: name)) in subjects.entries.indexed)
              ListRow(
                flat: true,
                showDivider: i < subjects.length - 1,
                leading: SubjectIconTile.forSubject(sid, icon: Icons.menu_book_rounded, size: 40),
                title: name,
                onTap: () => Navigator.pop(context, sid),
              ),
          ],
        ),
      );
      if (id == null) return;
    }
    if (!context.mounted) return;
    if (id == null) {
      // No subject known yet: the subject page offers random practice too.
      context.go(Routes.subjects);
      return;
    }
    await context.push(Uri(path: Routes.randomPractice, queryParameters: {'subjectId': id}).toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksOn = ref.watch(studentDecksEnabledProvider);
    final randomOn = ref.watch(remoteConfigProvider).value?.features.randomPractice ?? true;
    final myDecks = decksOn ? ref.watch(myDecksProvider).value : null;
    final home = ref.exists(homeProvider) ? ref.watch(homeProvider).value : null;
    final tiles = [
      if (decksOn)
        ShortcutTile(
          icon: Icons.collections_bookmark_rounded,
          hue: PlengoColors.pink,
          title: 'بطاقاتي',
          caption: myDecks == null ? 'مجموعاتك الخاصة' : groupCountLabel(myDecks.length),
          onTap: () => context.go(Routes.myDecks),
        ),
      ShortcutTile(
        icon: Icons.replay_circle_filled_rounded,
        hue: PlengoColors.red,
        title: 'مراجعة الأخطاء',
        caption: home == null ? null : '${home.activeMistakes} نشطة',
        onTap: () => context.go(Routes.mistakes),
      ),
      ShortcutTile(
        icon: Icons.insights_rounded,
        hue: PlengoColors.blue,
        title: 'إحصائياتي',
        caption: 'تقدّمك ونتائجك',
        onTap: () => context.go(Routes.stats),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, t) in tiles.indexed) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: t)],
            ],
          ),
        ),
        if (randomOn) ...[
          const SizedBox(height: PlengoSpace.listGap),
          ListRow(
            icon: Icons.shuffle_rounded,
            hue: PlengoColors.orange,
            title: 'تدريب عشوائي',
            caption: 'اختر الوحدات والنوع والعدد (5–50)',
            onTap: () => _randomPractice(context, ref),
          ),
        ],
      ],
    );
  }
}
