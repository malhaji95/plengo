import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../../shared/widgets/async_view.dart';
import 'exam_screen.dart';
import 'practice_attempt_screen.dart';
import 'quiz_providers.dart';
import 'results_screen.dart';

/// What `/attempts/:id` opens. Offline, a cached exam still opens (spec §15.2).
final _attemptEntryProvider = FutureProvider.autoDispose.family<Attempt, String>((ref, id) async {
  try {
    return await ref.watch(learningRepositoryProvider).attempt(id);
  } catch (e) {
    final draft = isOffline(e) ? await ref.read(examStoreProvider).draft(id) : null;
    if (draft == null) rethrow;
    return draft.attempt;
  }
});

/// `/attempts/:id`: practice, exam or results depending on the attempt.
class AttemptRoute extends ConsumerWidget {
  const AttemptRoute({super.key, required this.attemptId});

  final String attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(_attemptEntryProvider(attemptId));
    return switch (entry) {
      AsyncData(value: final a) when a.attempt.status == AttemptStatus.submitted => ResultsScreen(attemptId: attemptId),
      AsyncData(value: final a) when a.attempt.mode == AttemptSummaryMode.exam => ExamScreen(attemptId: attemptId),
      AsyncData(value: final a) => PracticeAttemptScreen(attempt: a),
      _ => Scaffold(
        appBar: AppBar(),
        body: AsyncView(
          value: entry,
          onRetry: () => ref.invalidate(_attemptEntryProvider(attemptId)),
          data: (_) => const SizedBox(),
        ),
      ),
    };
  }
}
