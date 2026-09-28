import 'dart:convert';

import 'package:drift/drift.dart';

import '../api/generated/export.dart';
import '../db/app_database.dart';

/// A locally kept exam answer (spec §15.2: answers are autosaved locally and to the server).
class LocalAnswer {
  const LocalAnswer({
    required this.questionId,
    this.selectedOptionId,
    this.writtenAnswer,
    this.flagged = false,
    this.timeSpentMs,
    this.dirty = true,
  });

  final String questionId;
  final String? selectedOptionId;
  final String? writtenAnswer;
  final bool flagged;
  final int? timeSpentMs;

  /// Not yet acknowledged by the server.
  final bool dirty;

  bool get answered => selectedOptionId != null || (writtenAnswer?.trim().isNotEmpty ?? false);

  LocalAnswer copyWith({
    String? selectedOptionId,
    String? writtenAnswer,
    bool? flagged,
    int? timeSpentMs,
    bool? dirty,
  }) => LocalAnswer(
    questionId: questionId,
    selectedOptionId: selectedOptionId ?? this.selectedOptionId,
    writtenAnswer: writtenAnswer ?? this.writtenAnswer,
    flagged: flagged ?? this.flagged,
    timeSpentMs: timeSpentMs ?? this.timeSpentMs,
    dirty: dirty ?? this.dirty,
  );

  SubmitAnswer toSubmit() => SubmitAnswer(
    questionId: questionId,
    selectedOptionId: selectedOptionId,
    writtenAnswer: writtenAnswer,
    flagged: flagged,
    timeSpentMs: timeSpentMs,
  );
}

/// A cached exam: the attempt as the server last sent it, plus local state.
class ExamDraft {
  const ExamDraft({required this.attempt, required this.submitPending, this.timeSpentMs});

  final Attempt attempt;
  final bool submitPending;
  final int? timeSpentMs;
}

/// Exams in progress in the encrypted database, so they survive connection drops and restarts.
/// Submissions made offline stay pending until [pendingSubmissions] are sent (spec §37.5).
class ExamStore {
  ExamStore(this.db);

  final AppDatabase db;

  Future<void> saveAttempt(Attempt attempt, {bool? submitPending, int? timeSpentMs}) async {
    final existing = await _draftRow(attempt.attempt.id);
    await db
        .into(db.examDrafts)
        .insertOnConflictUpdate(
          ExamDraftsCompanion.insert(
            attemptId: attempt.attempt.id,
            attempt: jsonEncode(attempt.toJson()),
            submitPending: Value(submitPending ?? existing?.submitPending ?? false),
            timeSpentMs: Value(timeSpentMs ?? existing?.timeSpentMs),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<ExamDraftRow?> _draftRow(String attemptId) =>
      (db.select(db.examDrafts)..where((t) => t.attemptId.equals(attemptId))).getSingleOrNull();

  Future<ExamDraft?> draft(String attemptId) async {
    final row = await _draftRow(attemptId);
    return row == null ? null : _toDraft(row);
  }

  ExamDraft _toDraft(ExamDraftRow row) => ExamDraft(
    attempt: Attempt.fromJson(jsonDecode(row.attempt) as Map<String, dynamic>),
    submitPending: row.submitPending,
    timeSpentMs: row.timeSpentMs,
  );

  Future<List<ExamDraft>> pendingSubmissions() async {
    final rows = await (db.select(db.examDrafts)..where((t) => t.submitPending.equals(true))).get();
    return rows.map(_toDraft).toList();
  }

  Future<Map<String, LocalAnswer>> answers(String attemptId) async {
    final rows = await (db.select(db.examAnswers)..where((t) => t.attemptId.equals(attemptId))).get();
    return {
      for (final r in rows)
        r.questionId: LocalAnswer(
          questionId: r.questionId,
          selectedOptionId: r.selectedOptionId,
          writtenAnswer: r.writtenAnswer,
          flagged: r.flagged,
          timeSpentMs: r.timeSpentMs,
          dirty: r.dirty,
        ),
    };
  }

  Future<void> putAnswer(String attemptId, LocalAnswer a) => db
      .into(db.examAnswers)
      .insertOnConflictUpdate(
        ExamAnswersCompanion.insert(
          attemptId: attemptId,
          questionId: a.questionId,
          selectedOptionId: Value(a.selectedOptionId),
          writtenAnswer: Value(a.writtenAnswer),
          flagged: Value(a.flagged),
          timeSpentMs: Value(a.timeSpentMs),
          dirty: Value(a.dirty),
        ),
      );

  /// Marks an answer as saved on the server, unless it changed again meanwhile.
  Future<void> markClean(String attemptId, LocalAnswer sent) async {
    final current = (await answers(attemptId))[sent.questionId];
    if (current == null ||
        current.selectedOptionId != sent.selectedOptionId ||
        current.writtenAnswer != sent.writtenAnswer ||
        current.flagged != sent.flagged) {
      return;
    }
    await putAnswer(attemptId, current.copyWith(dirty: false));
  }

  /// The attempt reached the server: nothing local is needed any more.
  Future<void> remove(String attemptId) => db.transaction(() async {
    await (db.delete(db.examAnswers)..where((t) => t.attemptId.equals(attemptId))).go();
    await (db.delete(db.examDrafts)..where((t) => t.attemptId.equals(attemptId))).go();
  });
}
