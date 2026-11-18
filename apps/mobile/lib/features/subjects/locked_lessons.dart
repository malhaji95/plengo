import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../access/access_banner.dart' show LockedNotice;
import '../access/access_providers.dart';

/// The lessons of a subject's general content that are locked for the student (v3 §3, black-and-white
/// stations with a lock).
///
/// The outline carries access per subject only, not per lesson, so the lock is derived from data the
/// app already loads:
/// - with access to the subject ([ScopeAccess.hasAccess]: an entitlement or a running promotion)
///   nothing is locked;
/// - otherwise a lesson is open when something in it is: a quiz or deck placed on the lesson that the
///   server reports as not locked (its free rules, including the default free first lessons, open
///   them), or progress the student already made in it ([percents] above 0);
/// - every other lesson is locked.
///
/// Returns null while [quizzes] or [decks] are still loading, so stations do not flash locked; a list
/// that failed to load counts as empty. Free questions are not listed per lesson, so a lesson whose
/// only free content is questions shows locked: its sheet keeps «عرض الدرس» to reach them.
Set<String>? lockedLessonIds({
  required SubjectOutline outline,
  required AsyncValue<List<StudentQuiz>> quizzes,
  required AsyncValue<List<StudentDeck>> decks,
  required Map<String, int> percents,
}) {
  if (outline.access.hasAccess) return const {};
  if (quizzes.isLoading || decks.isLoading) return null;
  final open = {
    for (final q in quizzes.value ?? const <StudentQuiz>[])
      if (!q.locked && q.teacherTrackId == null && q.lessonId != null) q.lessonId!,
    for (final d in decks.value ?? const <StudentDeck>[])
      if (!d.locked && d.teacherTrackId == null && d.lessonId != null) d.lessonId!,
    for (final e in percents.entries)
      if (e.value > 0) e.key,
  };
  return {
    for (final l in [...outline.units.expand((u) => u.lessons), ...outline.lessons])
      if (!open.contains(l.id)) l.id,
  };
}

/// The sheet a locked station opens: «هذا المحتوى يحتاج إلى تفعيل» with «إدخال كود التفعيل» (only with
/// COUPON_REDEMPTION; without it the content is just unavailable), and «عرض الدرس» for whatever is free
/// inside the lesson.
Future<void> showLockedLessonSheet(BuildContext context, {required String subjectId, required Lesson lesson}) =>
    showPlengoSheet<void>(
      context: context,
      builder: (_) => LockedLessonSheet(subjectId: subjectId, lesson: lesson),
    );

class LockedLessonSheet extends ConsumerWidget {
  const LockedLessonSheet({super.key, required this.subjectId, required this.lesson});

  final String subjectId;
  final Lesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    final redeem = ref.watch(couponRedemptionProvider);
    final red = PlengoColors.red;
    final router = GoRouter.of(context);
    return Column(
      key: const Key('lockedLesson.sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ExcludeSemantics(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: red.soft, shape: BoxShape.circle),
              child: Icon(Icons.lock_rounded, size: 40, color: red.ink),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            redeem ? 'هذا المحتوى يحتاج إلى تفعيل' : 'هذا المحتوى غير متاح على حسابك',
            textAlign: TextAlign.center,
            style: PlengoType.section.copyWith(color: s.ink),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          lesson.titleAr,
          textAlign: TextAlign.center,
          style: PlengoType.sub.copyWith(color: s.mute),
        ),
        const SizedBox(height: 16),
        if (redeem) ...[
          PlengoButton(
            label: 'إدخال كود التفعيل',
            icon: Icons.vpn_key_rounded,
            onPressed: () {
              Navigator.pop(context);
              router.push(LockedNotice(subjectId: subjectId).redeemLocation);
            },
          ),
          const SizedBox(height: 8),
        ],
        PlengoButton(
          label: 'عرض الدرس',
          variant: redeem ? PlengoButtonVariant.ghost : PlengoButtonVariant.secondary,
          onPressed: () {
            Navigator.pop(context);
            router.go('${Routes.subjects}/$subjectId/lessons/${lesson.id}');
          },
        ),
      ],
    );
  }
}
