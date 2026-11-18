import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';

/// Where diagrams are drawn from: the subject (or a teacher track), one unit, or some lessons.
/// [lessonIds] is comma-joined so the record compares by value (it keys a provider family).
typedef DiagramScope = ({String subjectId, String? teacherTrackId, String? unitId, String? lessonIds});

/// رسمات العلوم (V3_PLAN §9): list a scope, draw a practice set, check one diagram. Online only.
class DiagramRepository {
  DiagramRepository(this.client);

  final ApiClient client;

  Future<StudentDiagramList> list(DiagramScope scope) => guardApi(
    () async => (await client.api.diagrams.listDiagrams(
      subjectId: scope.subjectId,
      teacherTrackId: scope.teacherTrackId,
      unitId: scope.unitId,
      lessonIds: scope.lessonIds,
    )).data,
  );

  Future<DiagramPractice> start(DiagramPracticeRequest request) =>
      guardApi(() async => (await client.api.diagrams.startDiagramPractice(body: request)).data);

  /// Sends the typed names (blank ones are left out and count as wrong).
  Future<DiagramCheckResult> check(String diagramId, Map<int, String> answers) => guardApi(
    () async => (await client.api.diagrams.checkDiagram(
      id: diagramId,
      body: CheckDiagramRequest(
        answers: [
          for (final MapEntry(key: number, value: answer) in answers.entries)
            if (answer.trim().isNotEmpty) Answers(number: number, answer: answer.trim()),
        ],
      ),
    )).data,
  );
}

final diagramRepositoryProvider = Provider<DiagramRepository>(
  (ref) => DiagramRepository(ref.watch(apiClientProvider)),
);

/// The diagrams of a scope with the accessible and locked counts.
final diagramListProvider = FutureProvider.autoDispose.family<StudentDiagramList, DiagramScope>(
  (ref, scope) => ref.watch(diagramRepositoryProvider).list(scope),
);

/// The request body for a scope and a count.
DiagramPracticeRequest diagramPracticeRequest(DiagramScope scope, int count) => DiagramPracticeRequest(
  subjectId: scope.subjectId,
  teacherTrackId: scope.teacherTrackId,
  unitId: scope.unitId,
  lessonIds: scope.lessonIds?.split(','),
  count: count,
);
