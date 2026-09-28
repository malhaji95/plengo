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

/// Home (spec §19.1): greeting and bell, exam countdown, banners, today's work with goal and streak,
/// continue learning, my subjects and tracks, free content, followed teachers, mistakes shortcut.
/// Offline it falls back to what works without a connection.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    final unread = home.value?.unreadNotifications ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(_greeting(home.value?.greetingName ?? ref.watch(authControllerProvider).value?.fullName)),
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
        ],
      ),
      body: RefreshIndicator(
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
    final titles = Theme.of(context).textTheme.titleMedium;
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(title, style: titles),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (h.countdown != null) _CountdownCard(countdown: h.countdown!),
        if (h.banners.isNotEmpty) _BannerSlider(banners: h.banners),
        _TodayCard(today: h.today),
        if (h.activeMistakes > 0)
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('مراجعة الأخطاء'),
              subtitle: Text('${countedQuestions(h.activeMistakes)} في بنك الأخطاء'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.go(Routes.mistakes),
            ),
          ),
        section('متابعة التعلم'),
        if (h.resume.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('ابدأ من المواد'),
              subtitle: const Text('اختر مادة وابدأ التدريب أو الاختبارات'),
              onTap: () => context.go(Routes.subjects),
            ),
          )
        else
          for (final r in h.resume) ResumeTile(item: r),
        if (h.myAccess.isNotEmpty) ...[
          section('موادّي ومساراتي'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in h.myAccess)
                ActionChip(
                  avatar: Icon(
                    e.scope.scopeType == AccessScopeScopeType.teacherTrack ? Icons.route_outlined : Icons.menu_book,
                    size: 18,
                  ),
                  label: Text(scopeTitle(e.scope)),
                  onPressed: () => context.go(
                    e.scope.scopeType == AccessScopeScopeType.teacherTrack
                        ? '${Routes.tracks}/${e.scope.teacherTrackId}'
                        : '${Routes.subjects}/${e.scope.subjectId}',
                  ),
                ),
            ],
          ),
        ],
        if (h.freeSubjects.isNotEmpty) ...[
          section('محتوى مجاني'),
          for (final f in h.freeSubjects)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.lock_open_outlined),
                title: Text(f.nameAr),
                subtitle: Text('${f.freeCount} عنصراً مجانياً'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => context.go('${Routes.subjects}/${f.subjectId}'),
              ),
            ),
        ],
        if (h.followedTeachers.isNotEmpty) ...[
          section('مدرسون أتابعهم'),
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

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.countdown});

  final ExamCountdown countdown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.event_outlined, color: scheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                countdownText(countdown),
                style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('اليوم', style: Theme.of(context).textTheme.titleMedium)),
                Icon(Icons.local_fire_department, color: t.streak > 0 ? Colors.deepOrange : scheme.outline),
                const SizedBox(width: 4),
                Text(streakText(t.streak)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text(t.goalMet ? 'أنجزت هدف اليوم ✓' : 'هدف اليوم: ${t.done} من ${t.goal}')),
                TextButton(onPressed: () => editDailyGoal(context, ref, t.goal), child: const Text('تعديل الهدف')),
              ],
            ),
            LinearProgressIndicator(
              value: t.goal == 0 ? 0 : (t.done / t.goal).clamp(0, 1).toDouble(),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            if (t.dueCards > 0)
              FilledButton.icon(
                onPressed: () => context.push(Routes.dueStudy),
                icon: const Icon(Icons.style_outlined),
                label: Text('مراجعة البطاقات المستحقة (${t.dueCards})'),
              )
            else
              Text('لا بطاقات مستحقة الآن', style: TextStyle(color: scheme.outline)),
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
        Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_off_outlined),
            title: const Text('أنت غير متصل بالإنترنت'),
            subtitle: const Text('يمكنك متابعة المراجعة والمحتوى المحمّل'),
            trailing: TextButton(onPressed: () => ref.invalidate(homeProvider), child: const Text('تحديث')),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.style_outlined),
            title: const Text('المراجعة'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.go(Routes.review),
          ),
        ),
        if (ref.watch(offlinePacksAvailableProvider))
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_done_outlined),
              title: const Text('المحتوى المحمّل'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.go(Routes.offlineStorage),
            ),
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
    final (IconData icon, String action) = switch (r.activityType) {
      ResumeItemActivityType.quiz => (Icons.assignment_outlined, r.attemptId != null ? 'متابعة الاختبار' : 'اختبار'),
      ResumeItemActivityType.deck => (Icons.style_outlined, 'بطاقات'),
      _ => (Icons.quiz_outlined, 'أسئلة'),
    };
    final where = [
      r.subjectNameAr,
      if (r.trackTitleAr != null) r.trackTitleAr!,
      if (r.lessonNameAr != null) r.lessonNameAr!,
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(r.itemTitleAr ?? r.unitNameAr ?? r.subjectNameAr),
        subtitle: Text('$action · ${where.join(' · ')}'),
        trailing: const Icon(Icons.chevron_left),
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
      ),
    );
  }
}
