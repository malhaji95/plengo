import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/network_avatar.dart';
import '../access/access_format.dart';
import '../offline/offline_providers.dart';
import 'home_providers.dart';
import 'notification_screens.dart';
import '../../shared/widgets/responsive.dart';
import '../../shared/widgets/ui_kit.dart';
import '../../app/theme.dart';

/// Home (spec §19.1): greeting and bell, exam countdown, banners, today's work with goal and streak,
/// continue learning, my subjects and tracks, free content, followed teachers, mistakes shortcut.
/// Offline it falls back to what works without a connection.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    final unread = home.value?.unreadNotifications ?? 0;
    final me = ref.watch(authControllerProvider).value;
    final name = home.value?.greetingName ?? me?.fullName;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 16,
        title: Row(
          children: [
            NetworkAvatar(url: me?.avatarUrl, name: name ?? '', radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting(name), overflow: TextOverflow.ellipsis),
                  Text(
                    'واصل رحلتك التعليمية',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'الإشعارات',
            onPressed: () => context.push(Routes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 99 ? '99+' : '$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 8),
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
            _ => const Center(child: CircularProgressIndicator()),
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

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.home});

  final Home home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = home;
    final subjects = [
      for (final e in h.myAccess)
        (
          title: scopeTitle(e.scope),
          subtitle: scopeSubtitle(e.scope),
          track: e.scope.scopeType == AccessScopeScopeType.teacherTrack,
          path: e.scope.scopeType == AccessScopeScopeType.teacherTrack
              ? '${Routes.tracks}/${e.scope.teacherTrackId}'
              : '${Routes.subjects}/${e.scope.subjectId}',
        ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (h.countdown != null) _CountdownCard(countdown: h.countdown!),
        if (h.banners.isNotEmpty) _BannerSlider(banners: h.banners),
        _TodayCard(today: h.today),
        if (h.activeMistakes > 0)
          NavCard(
            icon: Icons.replay_rounded,
            tint: BrandColors.tintRed,
            title: 'مراجعة الأخطاء',
            subtitle: '${countedQuestions(h.activeMistakes)} في بنك الأخطاء',
            onTap: () => context.go(Routes.mistakes),
          ),
        const SectionHeader('متابعة التعلم'),
        if (h.resume.isEmpty)
          NavCard(
            icon: Icons.menu_book_rounded,
            tint: BrandColors.tintYellow,
            title: 'ابدأ من المواد',
            subtitle: 'اختر مادة وابدأ التدريب أو الاختبارات',
            onTap: () => context.go(Routes.subjects),
          )
        else
          for (final r in h.resume) ResumeTile(item: r),
        if (subjects.isNotEmpty) ...[
          SectionHeader('موادّي ومساراتي', action: 'كل المواد', onAction: () => context.go(Routes.subjects)),
          _TileRow(
            children: [
              for (final (i, sub) in subjects.indexed)
                BrandTile(
                  index: i,
                  icon: sub.track ? Icons.route_rounded : Icons.menu_book_rounded,
                  title: sub.title,
                  subtitle: sub.subtitle,
                  onTap: () => context.go(sub.path),
                ),
            ],
          ),
        ],
        if (h.freeSubjects.isNotEmpty) ...[
          const SectionHeader('محتوى مجاني'),
          _TileRow(
            children: [
              for (final (i, f) in h.freeSubjects.indexed)
                BrandTile(
                  index: i + subjects.length,
                  icon: Icons.lock_open_rounded,
                  title: f.nameAr,
                  subtitle: '${f.freeCount} عنصراً مجانياً',
                  onTap: () => context.go('${Routes.subjects}/${f.subjectId}'),
                ),
            ],
          ),
        ],
        if (h.followedTeachers.isNotEmpty) ...[
          const SectionHeader('مدرسون أتابعهم'),
          // Sized by its content, so larger font steps (§25) never overflow.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final t in h.followedTeachers)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.go('${Routes.teachers}/${t.id}'),
                    child: SizedBox(
                      width: 84,
                      child: Column(
                        children: [
                          NetworkAvatar(url: t.photoUrl, name: t.nameAr, radius: 28),
                          const SizedBox(height: 6),
                          Text(t.nameAr, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A horizontal strip of tiles that keeps its natural height at every font size.
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
            for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(width: 10), c],
          ],
        ),
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.countdown});

  final ExamCountdown countdown;

  @override
  Widget build(BuildContext context) {
    // Brand yellow with dark text (yellow never carries white text: 1.4:1).
    return Card(
      color: BrandColors.yellow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const IconBadge(Icons.event_rounded, tint: Colors.white, color: BrandColors.ink, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                countdownText(countdown),
                style: const TextStyle(color: BrandColors.ink, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerSlider extends ConsumerStatefulWidget {
  const _BannerSlider({required this.banners});

  final List<HomeBanner> banners;

  @override
  ConsumerState<_BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends ConsumerState<_BannerSlider> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    final first = banners.first;
    final ratio = (first.width ?? 0) > 0 && (first.height ?? 0) > 0 ? first.width! / first.height! : 16 / 9;
    final image = ref.watch(bannerImageBuilderProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: ratio.clamp(1.2, 3.5),
            child: PageView.builder(
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
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: b.action == BannerAction.none
                            ? null
                            : () => openAction(context, ref, b.action, b.actionTarget),
                        child: image(context, b),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (banners.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < banners.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.today});

  final Today today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = today;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final ratio = t.goal == 0 ? 0.0 : (t.done / t.goal).clamp(0, 1).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('اليوم', style: text.titleMedium)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.streak > 0 ? BrandColors.tintOrange : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 18,
                        color: t.streak > 0 ? const Color(0xFFB45309) : scheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          streakText(t.streak),
                          style: TextStyle(
                            color: t.streak > 0 ? BrandColors.ink : scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ProgressRing(value: ratio, label: '${(ratio * 100).round()}%', size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.goalMet ? 'أنجزت هدف اليوم ✓' : 'هدف اليوم: ${t.done} من ${t.goal}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          onPressed: () => editDailyGoal(context, ref, t.goal),
                          child: const Text('تعديل الهدف'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (t.dueCards > 0)
              FilledButton.icon(
                onPressed: () => context.push(Routes.dueStudy),
                icon: const Icon(Icons.style_outlined),
                label: Text('مراجعة البطاقات المستحقة (${t.dueCards})'),
              )
            else
              Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: BrandColors.success(Theme.of(context).brightness)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('لا بطاقات مستحقة الآن', style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// What still works without a connection: due cards (studied locally), student decks and downloads.
class _OfflineHome extends ConsumerWidget {
  const _OfflineHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        NavCard(
          icon: Icons.cloud_off_rounded,
          tint: BrandColors.tintOrange,
          title: 'أنت غير متصل بالإنترنت',
          subtitle: 'يمكنك متابعة المراجعة والمحتوى المحمّل',
          trailing: TextButton(onPressed: () => ref.invalidate(homeProvider), child: const Text('تحديث')),
        ),
        NavCard(icon: Icons.style_rounded, title: 'المراجعة', onTap: () => context.go(Routes.review)),
        if (ref.watch(offlinePacksAvailableProvider))
          NavCard(
            icon: Icons.download_done_rounded,
            tint: BrandColors.tintGreen,
            title: 'المحتوى المحمّل',
            onTap: () => context.go(Routes.offlineStorage),
          ),
      ],
    );
  }
}

class ResumeTile extends StatelessWidget {
  const ResumeTile({super.key, required this.item});

  final ResumeItem item;

  @override
  Widget build(BuildContext context) {
    final r = item;
    final (IconData icon, Color tint, String action) = switch (r.activityType) {
      ResumeItemActivityType.quiz => (
        Icons.assignment_rounded,
        BrandColors.tintBlue,
        r.attemptId != null ? 'متابعة الاختبار' : 'اختبار',
      ),
      ResumeItemActivityType.deck => (Icons.style_rounded, BrandColors.tintPink, 'بطاقات'),
      _ => (Icons.quiz_rounded, BrandColors.tintGreen, 'أسئلة'),
    };
    final where = [
      r.subjectNameAr,
      if (r.trackTitleAr != null) r.trackTitleAr!,
      if (r.lessonNameAr != null) r.lessonNameAr!,
    ];
    return NavCard(
      icon: icon,
      tint: tint,
      title: r.itemTitleAr ?? r.unitNameAr ?? r.subjectNameAr,
      subtitle: '$action · ${where.join(' · ')}',
      onTap: () {
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
      },
    );
  }
}
