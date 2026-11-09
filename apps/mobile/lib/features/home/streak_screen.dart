import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../core/srs/scheduler.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/responsive.dart';
import '../flashcards/flashcard_providers.dart' show clockProvider;
import 'home_providers.dart';

/// The streak moment after the first finished activity of the day (V-Streak, flag
/// `RedesignFlags.newStreakMoment`): the flame, the streak (days with the daily goal met, DECISIONS #2),
/// one encouraging line and the last seven days. «متابعة» returns to where the student came from.
class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  static const _dayNames = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
  static const _dayLetters = ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];

  /// Weekday (0 = Sunday) of a business day: day 0 starts on Thursday 1970-01-01, 04:00 Damascus.
  static int weekdayOf(int businessDay) => (businessDay + 4) % 7;

  /// One encouraging line; never a threat or a reproach.
  static String encouragement(int streak, String? firstName) {
    final you = firstName == null || firstName.isEmpty ? 'أحسنت' : 'أحسنت يا $firstName';
    if (streak <= 0) return 'كل يوم بداية جديدة. حقّق هدفك اليوم لتبدأ سلسلتك.';
    if (streak >= 7) return '$you! استمر على هذا الإيقاع.';
    final next = streak + 1;
    final target = switch (next) {
      7 => 'أسبوع كامل',
      2 => 'يومين متتاليين',
      _ => '$next أيام متتالية',
    };
    return '$you. حقّق هدفك غداً لتصل إلى $target.';
  }

  void _continue(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    final today = businessDay(ref.watch(clockProvider)());
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: switch (home) {
            AsyncData(value: final h) => _StreakBody(home: h, today: today),
            AsyncError() => const _StreakBody(home: null, today: 0),
            _ => const Center(
              child: SkeletonGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Skeleton(height: 144, circle: true),
                    SizedBox(height: 16),
                    Skeleton(width: 80, height: 64),
                    SizedBox(height: 16),
                    Skeleton(width: 240, height: 24),
                  ],
                ),
              ),
            ),
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 8, PlengoSpace.screen, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
              child: PlengoButton(
                label: 'متابعة',
                variant: PlengoButtonVariant.brand,
                onPressed: () => _continue(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakBody extends StatelessWidget {
  const _StreakBody({required this.home, required this.today});

  /// Null when Home could not load (offline): the flame and title only, no numbers.
  final Home? home;
  final int today;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final orange = PlengoColors.orange;
    final h = home;
    final streak = h?.today.streak ?? 0;
    final first = h?.greetingName.trim().split(RegExp(r'\s+')).first;
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 48, PlengoSpace.screen, 24),
      children: [
        Center(
          child: ConfettiDots(
            spread: 18,
            child: ExcludeSemantics(
              child: Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(color: orange.soft, shape: BoxShape.circle),
                child: Icon(Icons.local_fire_department_rounded, size: 80, color: orange.base),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (h != null)
          Text(
            '$streak',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: PlengoType.family,
              fontSize: 64,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: s.isDark ? orange.base : orange.ink,
            ),
          ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            'أيام متتالية حققت فيها هدفك',
            textAlign: TextAlign.center,
            style: PlengoType.title.copyWith(fontSize: 24, color: s.ink),
          ),
        ),
        if (h != null) ...[
          const SizedBox(height: 8),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                StreakScreen.encouragement(streak, first),
                textAlign: TextAlign.center,
                style: PlengoType.sub.copyWith(color: s.mute),
              ),
            ),
          ),
          if (h.today.week.isNotEmpty) ...[const SizedBox(height: 20), _WeekRow(week: h.today.week, today: today)],
        ],
      ],
    );
  }
}

/// The last seven business days (oldest first, today last): a filled orange circle with ✓ when the goal
/// was met, today with a double ring.
class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.week, required this.today});

  final List<bool> week;
  final int today;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final orange = PlengoColors.orange;
    final met = week.where((d) => d).length;
    final n = week.length;
    return PlengoCard(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 14),
      child: Semantics(
        container: true,
        label: 'حققت هدفك في $met من آخر $n أيام',
        child: Row(
          children: [
            for (var i = 0; i < n; i++)
              Expanded(
                child: Builder(
                  builder: (context) {
                    final isToday = i == n - 1;
                    final done = week[i];
                    final wd = StreakScreen.weekdayOf(today - (n - 1 - i));
                    final state = done ? 'مكتمل' : (isToday ? 'لم يكتمل بعد' : 'لم يكتمل');
                    return Semantics(
                      label: '${StreakScreen._dayNames[wd]}${isToday ? '، اليوم' : ''}: $state',
                      container: true,
                      excludeSemantics: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            StreakScreen._dayLetters[wd],
                            style: PlengoType.chip.copyWith(color: isToday ? s.ink : s.mute),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 34,
                            height: 34,
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done ? orange.base : s.track,
                              boxShadow: isToday
                                  ? [
                                      BoxShadow(color: orange.base, spreadRadius: 5),
                                      BoxShadow(color: s.card, spreadRadius: 2.5),
                                    ]
                                  : null,
                            ),
                            child: done ? const Icon(Icons.check_rounded, size: 20, color: PlengoColors.ink) : null,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
