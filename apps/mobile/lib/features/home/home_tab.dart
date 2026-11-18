import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/redesign_flags.dart';
import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../shared/ui/ui.dart';
import '../shell/app_drawer.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/network_avatar.dart';
import '../../shared/widgets/responsive.dart';
import '../access/access_format.dart';
import '../learning/scope_learning.dart' show progressProvider;
import '../offline/offline_providers.dart';
import '../flashcards/hard_cards.dart';
import '../loyalty/loyalty_screen.dart' show LoyaltyPointsChip;
import 'auto_advance.dart';
import 'home_providers.dart';
import '../my_subjects/my_subjects_providers.dart' show nextLessonsProvider;
import 'next_lesson_carousel.dart';
import 'notification_screens.dart';

/// Home (spec §19.1, V-Home, v3 §2): ☰ menu, greeting and bell, the Continue hero (latest item only),
/// «راجع الدرس التالي:», today's work with goal, streak and the hard-cards shortcut, exam countdown,
/// auto-rotating banners, my subjects and tracks, free content and followed teachers. [RedesignFlags.homeOrderV2] picks the order. Offline it falls back to what works without
/// a connection (V-Offline); while loading it shows a skeleton of the layout (V-Loading).
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    final unread = home.value?.unreadNotifications ?? 0;
    final me = ref.watch(authControllerProvider).value;
    final name = home.value?.greetingName ?? me?.fullName;
    final s = context.surface;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: DrawerMenuButton.leadingOf(context) == null ? PlengoSpace.screen : 4,
        automaticallyImplyLeading: false,
        leading: DrawerMenuButton.leadingOf(context),
        leadingWidth: kPlengoLeadingWidth,
        title: Row(
          children: [
            NetworkAvatar(url: me?.avatarUrl, name: name ?? '', radius: 23),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _greeting(name),
                    overflow: TextOverflow.ellipsis,
                    style: PlengoType.rowTitle.copyWith(fontSize: 17, color: s.ink),
                  ),
                  Text(
                    'واصل رحلتك التعليمية',
                    overflow: TextOverflow.ellipsis,
                    style: PlengoType.caption.copyWith(color: s.mute),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          const LoyaltyPointsChip(),
          PlengoIconButton(
            icon: Icons.notifications_outlined,
            tooltip: 'الإشعارات',
            badge: unread,
            onPressed: () => context.push(Routes.notifications),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ContentWidth(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(homeProvider.future),
          child: switch (home) {
            AsyncData(value: final h) => _HomeBody(home: h),
            AsyncError(error: final ApiException e) when e.code == 'NETWORK_ERROR' => const _OfflineHome(),
            AsyncError() => ListView(
              children: [
                AsyncView(value: home, onRetry: () => ref.invalidate(homeProvider), data: (_) => const SizedBox()),
              ],
            ),
            _ => const _HomeSkeleton(),
          },
        ),
      ),
    );
  }

  static String _greeting(String? name) {
    final first = name?.trim().split(RegExp(r'\s+')).first ?? '';
    return first.isEmpty ? 'مرحباً' : 'مرحباً، $first';
  }
}

const _listPadding = EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 4, PlengoSpace.screen, 24);

/// Width from which Continue and Today sit side by side (V-Web).
const _sideBySideWidth = 560.0;

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.home});

  final Home home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = home;
    final v2 = RedesignFlags.homeOrderV2;
    final countdown = h.countdown == null ? null : _CountdownCard(countdown: h.countdown!);
    final banners = h.banners.isEmpty ? null : BannerSlider(banners: h.banners);
    final today = _TodayCard(today: h.today);
    final cont = _ContinueSection(resume: h.resume, showHeader: !v2);
    // Hides itself while loading or when there is no next lesson.
    const next = NextLessonCarousel();
    final subjects = h.myAccess.isEmpty ? null : _MySubjects(access: h.myAccess);
    final free = h.freeSubjects.isEmpty ? null : _FreeContent(items: h.freeSubjects);
    final teachers = h.followedTeachers.isEmpty ? null : _FollowedTeachers(teachers: h.followedTeachers);

    return LayoutBuilder(
      builder: (context, box) {
        final wide = v2 && box.maxWidth - _listPadding.horizontal >= _sideBySideWidth;
        final sections = <Widget?>[
          if (v2) ...[
            if (wide) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cont),
                  const SizedBox(width: PlengoSpace.section),
                  Expanded(child: today),
                ],
              ),
              next,
            ] else ...[
              cont,
              next,
              today,
            ],
            countdown,
            banners,
            subjects,
            free,
            teachers,
          ] else ...[
            countdown,
            banners,
            today,
            cont,
            next,
            subjects,
            free,
            teachers,
          ],
        ];
        final shown = sections.whereType<Widget>().toList();
        // The carousel brings no gap of its own while it is empty.
        Widget gapBefore(Widget w) => w is NextLessonCarousel
            ? Consumer(
                builder: (context, ref, _) => (ref.watch(nextLessonsProvider).value ?? const []).isEmpty
                    ? const SizedBox.shrink()
                    : const SizedBox(height: PlengoSpace.section),
              )
            : const SizedBox(height: PlengoSpace.section);
        return ListView(
          padding: _listPadding,
          children: [
            for (final (i, w) in shown.indexed) ...[if (i > 0) gapBefore(w), w],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------------------------------
// Continue

/// Opens a resume item, whatever its type (quiz attempt, quiz, deck, lesson questions, track, subject).
void openResume(BuildContext context, ResumeItem r) {
  if (r.attemptId != null) {
    context.push('/attempts/${r.attemptId}');
  } else if (r.activityType == ResumeItemActivityType.quiz && r.itemId != null) {
    context.go('${Routes.quizzes}/${r.itemId}');
  } else if (r.activityType == ResumeItemActivityType.deck && r.itemId != null) {
    context.go('${Routes.decks}/${r.itemId}');
  } else if (r.lessonId != null) {
    context.go('${Routes.subjects}/${r.subjectId}/questions?lessonId=${r.lessonId}');
  } else if (r.teacherTrackId != null) {
    context.go('${Routes.tracks}/${r.teacherTrackId}');
  } else {
    context.go('${Routes.subjects}/${r.subjectId}');
  }
}

({IconData icon, PlengoHue hue, String action}) _resumeKind(ResumeItem r) => switch (r.activityType) {
  ResumeItemActivityType.quiz => (
    icon: Icons.assignment_rounded,
    hue: PlengoColors.blue,
    action: r.attemptId != null ? 'متابعة الاختبار' : 'اختبار',
  ),
  ResumeItemActivityType.deck => (icon: Icons.style_rounded, hue: PlengoColors.pink, action: 'بطاقات'),
  _ => (icon: Icons.quiz_rounded, hue: PlengoColors.green, action: 'أسئلة'),
};

String _resumeTitle(ResumeItem r) => r.itemTitleAr ?? r.unitNameAr ?? r.subjectNameAr;

String _resumeSubtitle(ResumeItem r) {
  final where = [
    r.subjectNameAr,
    if (r.trackTitleAr != null) r.trackTitleAr!,
    if (r.lessonNameAr != null) r.lessonNameAr!,
  ];
  return '${_resumeKind(r).action} · ${where.join(' · ')}';
}

/// The blue Continue hero for the latest resume item only (v3 §2: no older rows under it), or a
/// start-here hero.
class _ContinueSection extends StatelessWidget {
  const _ContinueSection({required this.resume, required this.showHeader});

  final List<ResumeItem> resume;

  /// The original order keeps its «متابعة التعلم» section title.
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader) const SectionHeader('متابعة التعلم', top: 0),
        if (resume.isEmpty) const _StartHero() else _ContinueHero(item: resume.first),
      ],
    );
  }
}

class _ContinueHero extends ConsumerWidget {
  const _ContinueHero({required this.item});

  final ResumeItem item;

  /// DECISIONS #5: the lesson's completion, else the unit's, else the subject's (or track's).
  static int? _percent(ScopeProgress? p, ResumeItem r) {
    if (p == null) return null;
    int? pick<T>(List<T> list, bool Function(T) match, int Function(T) value) {
      for (final e in list) {
        if (match(e)) return value(e);
      }
      return null;
    }

    final lesson = r.lessonId == null
        ? null
        : pick(p.lessons, (l) => l.lessonId == r.lessonId, (l) => l.completionPercent);
    final unit = r.unitId == null ? null : pick(p.units, (u) => u.unitId == r.unitId, (u) => u.completionPercent);
    return lesson ?? unit ?? p.completionPercent;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = item;
    final progress = ref.watch(progressProvider((subjectId: r.subjectId, teacherTrackId: r.teacherTrackId))).value;
    final pct = _percent(progress, r);
    final title = _resumeTitle(r);
    return PlengoHeroCard(
      onTap: () => openResume(context, r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('تابع من حيث توقفت', style: PlengoType.chip.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(title, style: PlengoType.section.copyWith(fontSize: 20, color: Colors.white)),
          ),
          const SizedBox(height: 4),
          Text(_resumeSubtitle(r), style: PlengoType.caption.copyWith(fontSize: 13, color: Colors.white)),
          if (pct != null) ...[
            const SizedBox(height: 12),
            PlengoProgressBar(
              value: pct / 100,
              label: '${percent(pct)} مكتمل',
              color: PlengoColors.yellow.base,
              trackColor: Colors.white.withValues(alpha: 0.3),
              labelColor: Colors.white,
            ),
          ],
          const SizedBox(height: 14),
          PlengoButton(
            label: 'تابع',
            icon: Icons.play_arrow_rounded,
            variant: PlengoButtonVariant.brand,
            semanticsLabel: 'تابع: $title',
            onPressed: () => openResume(context, r),
          ),
        ],
      ),
    );
  }
}

/// Nothing to resume yet: points to the subjects.
class _StartHero extends StatelessWidget {
  const _StartHero();

  @override
  Widget build(BuildContext context) {
    return PlengoHeroCard(
      onTap: () => context.go(Routes.subjects),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('متابعة التعلم', style: PlengoType.chip.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text('ابدأ من المواد', style: PlengoType.section.copyWith(fontSize: 20, color: Colors.white)),
          ),
          const SizedBox(height: 4),
          Text(
            'اختر مادة وابدأ التدريب أو الاختبارات',
            style: PlengoType.caption.copyWith(fontSize: 13, color: Colors.white),
          ),
          const SizedBox(height: 14),
          PlengoButton(
            label: 'المواد',
            icon: Icons.menu_book_rounded,
            variant: PlengoButtonVariant.brand,
            onPressed: () => context.go(Routes.subjects),
          ),
        ],
      ),
    );
  }
}

/// A resume item as a list row (the older items under the Continue hero).
class ResumeTile extends StatelessWidget {
  const ResumeTile({super.key, required this.item});

  final ResumeItem item;

  @override
  Widget build(BuildContext context) {
    final kind = _resumeKind(item);
    return ListRow(
      icon: kind.icon,
      hue: kind.hue,
      title: _resumeTitle(item),
      caption: _resumeSubtitle(item),
      onTap: () => openResume(context, item),
    );
  }
}

// ---------------------------------------------------------------------------------------------------
// Today

/// Today (v3 §2): the daily goal ring, the due cards (opening موادي) and «مراجعة البطاقات الصعبة»
/// (opening the saved cards) instead of the mistakes row.
class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.today});

  final Today today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = today;
    final s = context.surface;
    final ratio = t.goal == 0 ? 0.0 : (t.done / t.goal).clamp(0, 1).toDouble();
    final streakOn = t.streak > 0;
    final orange = PlengoColors.orange;
    return PlengoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('اليوم', style: PlengoType.section.copyWith(color: s.ink)),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: PlengoChip(
                  label: streakText(t.streak),
                  icon: Icons.local_fire_department_rounded,
                  hue: orange,
                  background: streakOn ? orange.soft : s.track,
                  foreground: streakOn ? orange.ink : s.mute,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ProgressRing(
                value: ratio,
                label: '${t.done}/${t.goal}',
                size: 76,
                semanticsLabel: 'هدف اليوم: ${t.done} من ${t.goal}',
                labelStyle: TextStyle(
                  fontFamily: PlengoType.family,
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                  color: s.ink,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.goalMet ? 'أنجزت هدف اليوم' : 'هدف اليوم: ${t.done} من ${t.goal}',
                      style: PlengoType.rowTitle.copyWith(color: s.ink),
                    ),
                    Text('بطاقات وإجابات', style: PlengoType.caption.copyWith(color: s.mute)),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: s.action,
                          padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
                          minimumSize: const Size(48, 48),
                          textStyle: PlengoType.buttonSmall,
                        ),
                        onPressed: () => editDailyGoal(context, ref, t.goal),
                        child: const Text('تعديل الهدف'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (t.dueCards > 0)
            PlengoButton(
              label: 'مراجعة البطاقات المستحقة (${t.dueCards})',
              icon: Icons.style_outlined,
              onPressed: () => context.go(Routes.mySubjects),
            )
          else
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 20, color: PlengoColors.green.ink),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('لا بطاقات مستحقة الآن', style: PlengoType.sub.copyWith(color: s.mute)),
                ),
              ],
            ),
          const SizedBox(height: PlengoSpace.listGap),
          const HardCardsRow(),
        ],
      ),
    );
  }
}

/// «مراجعة البطاقات الصعبة» (v3 §2, §8): opens the saved cards, hard ones first and marked «صعبة».
class HardCardsRow extends ConsumerWidget {
  const HardCardsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hard = ref.watch(hardCardsProvider).value?.length ?? 0;
    return ListRow(
      key: const Key('home.hardCards'),
      background: PlengoColors.orange.soft,
      leading: const SubjectIconTile(icon: Icons.local_fire_department_rounded, hue: PlengoColors.orange, size: 36),
      title: 'مراجعة البطاقات الصعبة',
      caption: hard > 0 ? '$hard من البطاقات تحتاج تركيزاً' : 'البطاقات التي تجدها صعبة والمحفوظة',
      onTap: () => context.go(Uri(path: Routes.saved, queryParameters: {'filter': 'cards'}).toString()),
    );
  }
}

// ---------------------------------------------------------------------------------------------------
// Countdown and banners

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.countdown});

  final ExamCountdown countdown;

  @override
  Widget build(BuildContext context) {
    final yellow = PlengoColors.yellow;
    // Brand yellow with dark text (yellow never carries white text).
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: yellow.base, borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            const ExcludeSemantics(child: Icon(Icons.schedule_rounded, size: 28, color: PlengoColors.ink)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('العدّ التنازلي', style: PlengoType.caption.copyWith(color: yellow.ink)),
                  Text(countdownText(countdown), style: PlengoType.rowTitle.copyWith(color: PlengoColors.ink)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Home banners (v3 §2): swipe, dots, and they rotate by themselves every [interval] (paused while
/// touched; never with reduced motion).
class BannerSlider extends ConsumerStatefulWidget {
  const BannerSlider({super.key, required this.banners});

  final List<HomeBanner> banners;

  static const interval = Duration(seconds: 5);

  @override
  ConsumerState<BannerSlider> createState() => BannerSliderState();
}

class BannerSliderState extends ConsumerState<BannerSlider> with AutoAdvance {
  int _page = 0;

  @override
  final pager = PageController();

  @override
  int get pageCount => widget.banners.length;

  @override
  Duration get autoAdvanceInterval => BannerSlider.interval;

  /// The banner shown.
  int get page => _page;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncAutoAdvance();
  }

  @override
  void didUpdateWidget(BannerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      if (_page >= widget.banners.length) _page = 0;
      syncAutoAdvance();
    }
  }

  @override
  void dispose() {
    pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final banners = widget.banners;
    final first = banners.first;
    final ratio = (first.width ?? 0) > 0 && (first.height ?? 0) > 0 ? first.width! / first.height! : 16 / 9;
    final image = ref.watch(bannerImageBuilderProvider);
    final radius = BorderRadius.circular(PlengoRadius.card);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: ratio.clamp(1.2, 3.5),
          child: holdOnTouch(
            PageView.builder(
              controller: pager,
              itemCount: banners.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final b = banners[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Semantics(
                    label: b.titleAr,
                    button: b.action != BannerAction.none,
                    child: ClipRRect(
                      borderRadius: radius,
                      child: ColoredBox(
                        color: PlengoColors.pink.soft,
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            onTap: b.action == BannerAction.none
                                ? null
                                : () => openAction(context, ref, b.action, b.actionTarget),
                            child: image(context, b),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (banners.length > 1)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 8),
            child: PageDots(
              count: banners.length,
              index: _page,
              label: 'البانر ${_page + 1} من ${banners.length}',
              active: s.action,
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------------
// My subjects, free content, teachers

/// A horizontal strip of cards that keeps its natural height at every font size.
class _TileRow extends StatelessWidget {
  const _TileRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(width: PlengoSpace.listGap), c],
          ],
        ),
      ),
    );
  }
}

class _MySubjects extends StatelessWidget {
  const _MySubjects({required this.access});

  final List<MyEntitlement> access;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      SectionHeader('موادّي ومساراتي', action: 'كل المواد', onAction: () => context.go(Routes.subjects), top: 0),
      _TileRow(children: [for (final e in access) _ScopeCard(scope: e.scope)]),
    ],
  );
}

/// A subject or track in its soft colour with an icon tile, its completion ring (DECISIONS #6) and the
/// unit progress caption.
class _ScopeCard extends ConsumerWidget {
  const _ScopeCard({required this.scope});

  final AccessScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = scope.scopeType == AccessScopeScopeType.teacherTrack;
    final hue = subjectHue(track ? (scope.teacherTrackId ?? scope.subjectId) : scope.subjectId);
    final progress = ref
        .watch(progressProvider((subjectId: scope.subjectId, teacherTrackId: track ? scope.teacherTrackId : null)))
        .value;
    final units = progress?.units ?? const <UnitProgress>[];
    final caption = !track && units.isNotEmpty
        ? () {
            final done = units.where((u) => u.completionPercent >= 100).length;
            return 'الوحدة ${(done + 1).clamp(1, units.length)} من ${units.length}';
          }()
        : scopeSubtitle(scope);
    final title = scopeTitle(scope);
    final path = track ? '${Routes.tracks}/${scope.teacherTrackId}' : '${Routes.subjects}/${scope.subjectId}';
    final pct = progress?.completionPercent;
    return SizedBox(
      width: 164,
      child: PlengoCard(
        color: hue.soft,
        radius: 22,
        padding: const EdgeInsetsDirectional.all(14),
        onTap: () => context.go(path),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubjectIconTile(icon: track ? Icons.route_rounded : Icons.menu_book_rounded, hue: hue, size: 40),
                const Spacer(),
                if (pct != null)
                  ProgressRing(
                    value: pct / 100,
                    label: '$pct%',
                    size: 46,
                    strokeWidth: 5,
                    color: hue.ink,
                    trackColor: Colors.white.withValues(alpha: 0.7),
                    semanticsLabel: 'مكتمل',
                    labelStyle: const TextStyle(
                      fontFamily: PlengoType.family,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: PlengoColors.ink,
                    ),
                  )
                else
                  const SizedBox.square(dimension: 46),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: PlengoType.rowTitle.copyWith(color: PlengoColors.ink),
            ),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: PlengoType.caption.copyWith(color: hue.ink, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreeContent extends StatelessWidget {
  const _FreeContent({required this.items});

  final List<FreeSubject> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      const SectionHeader('محتوى مجاني', top: 0),
      _TileRow(children: [for (final f in items) _FreeCard(item: f)]),
    ],
  );
}

/// A free subject: its cover (or its colour), name, free-item count and the «مجاني» chip.
class _FreeCard extends StatelessWidget {
  const _FreeCard({required this.item});

  final FreeSubject item;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final hue = subjectHue(item.subjectId);
    final placeholder = ColoredBox(
      color: hue.soft,
      child: Center(child: Icon(Icons.lock_open_rounded, color: hue.ink, size: 28)),
    );
    return SizedBox(
      width: 156,
      child: PlengoCard(
        radius: PlengoRadius.row,
        padding: const EdgeInsetsDirectional.all(12),
        onTap: () => context.go('${Routes.subjects}/${item.subjectId}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(PlengoRadius.iconTile),
                child: SizedBox(
                  height: 64,
                  width: double.infinity,
                  child: item.coverUrl == null
                      ? placeholder
                      : CachedNetworkImage(
                          imageUrl: item.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => placeholder,
                          errorWidget: (_, _, _) => placeholder,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.nameAr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: PlengoType.rowTitle.copyWith(fontSize: 14, color: s.ink),
            ),
            Text('${item.freeCount} عنصراً مجانياً', style: PlengoType.caption.copyWith(color: s.mute)),
            const Spacer(),
            const SizedBox(height: 6),
            const PlengoChip(label: 'مجاني', hue: PlengoColors.green),
          ],
        ),
      ),
    );
  }
}

class _FollowedTeachers extends StatelessWidget {
  const _FollowedTeachers({required this.teachers});

  final List<Teacher> teachers;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionHeader('مدرسون أتابعهم', top: 0),
        // Sized by its content, so larger font steps never overflow.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final t in teachers)
                Semantics(
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(PlengoRadius.iconTile),
                    onTap: () => context.go('${Routes.teachers}/${t.id}'),
                    child: SizedBox(
                      width: 86,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(shape: BoxShape.circle, color: subjectHue(t.id).base),
                              child: NetworkAvatar(url: t.photoUrl, name: t.nameAr, radius: 29),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.nameAr,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: PlengoType.caption.copyWith(fontWeight: FontWeight.w600, color: s.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------------
// Offline and loading

/// What still works without a connection (V-Offline): due cards (studied locally), student decks and
/// downloads, in a dark banner with links.
class _OfflineHome extends ConsumerWidget {
  const _OfflineHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    final yellow = PlengoColors.yellow.base;
    final link = TextButton.styleFrom(
      foregroundColor: yellow,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
      textStyle: PlengoType.buttonSmall.copyWith(fontSize: 13),
    );
    return ListView(
      padding: _listPadding,
      children: [
        Semantics(
          container: true,
          liveRegion: true,
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: PlengoColors.ink,
              borderRadius: BorderRadius.circular(PlengoRadius.card),
              border: s.isDark ? Border.all(color: s.line) : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Icon(Icons.cloud_off_rounded, color: yellow)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('أنت غير متصل بالإنترنت', style: PlengoType.rowTitle.copyWith(color: Colors.white)),
                      Text(
                        'يمكنك متابعة المراجعة والمحتوى المحمّل',
                        style: PlengoType.caption.copyWith(fontSize: 13, color: const Color(0xFFE8E3D8)),
                      ),
                      Wrap(
                        spacing: 4,
                        children: [
                          TextButton(
                            style: link,
                            onPressed: () => context.go(Routes.review),
                            child: const Text('المراجعة'),
                          ),
                          if (ref.watch(offlinePacksAvailableProvider))
                            TextButton(
                              style: link,
                              onPressed: () => context.go(Routes.offlineStorage),
                              child: const Text('المحتوى المحمّل'),
                            ),
                          TextButton(
                            style: link,
                            onPressed: () => ref.invalidate(homeProvider),
                            child: const Text('تحديث'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// V-Loading: skeleton blocks mirroring Continue, Today, the countdown and the subject cards.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: _listPadding,
    children: const [
      SkeletonGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Skeleton(height: 190, radius: PlengoRadius.hero),
            SizedBox(height: PlengoSpace.section),
            Skeleton(height: 220, radius: PlengoRadius.card),
            SizedBox(height: PlengoSpace.section),
            Skeleton(height: 64, radius: 22),
            SizedBox(height: PlengoSpace.section),
            Row(
              children: [
                Expanded(child: Skeleton(height: 150, radius: 22)),
                SizedBox(width: PlengoSpace.listGap),
                Expanded(child: Skeleton(height: 150, radius: 22)),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
