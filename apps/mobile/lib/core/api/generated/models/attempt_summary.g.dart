// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attempt_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttemptSummary _$AttemptSummaryFromJson(Map<String, dynamic> json) =>
    AttemptSummary(
      id: json['id'] as String,
      clientAttemptId: json['clientAttemptId'] as String,
      quizId: json['quizId'] as String?,
      source: $enumDecode(_$AttemptSummarySourceEnumMap, json['source']),
      mode: $enumDecode(_$AttemptSummaryModeEnumMap, json['mode']),
      titleAr: json['titleAr'] as String,
      subjectId: json['subjectId'] as String?,
      teacherTrackId: json['teacherTrackId'] as String?,
      filters: json['filters'] == null
          ? null
          : AttemptFilters.fromJson(json['filters'] as Map<String, dynamic>),
      status: $enumDecode(_$AttemptStatusEnumMap, json['status']),
      startedAt: json['startedAt'] as String,
      deadlineAt: json['deadlineAt'] as String?,
      submittedAt: json['submittedAt'] as String?,
      submittedLate: json['submittedLate'] as bool,
      totalCount: (json['totalCount'] as num).toInt(),
      answeredCount: (json['answeredCount'] as num).toInt(),
      correctCount: (json['correctCount'] as num?)?.toInt(),
      wrongCount: (json['wrongCount'] as num?)?.toInt(),
      skippedCount: (json['skippedCount'] as num?)?.toInt(),
      scorePercent: (json['scorePercent'] as num?)?.toInt(),
      passingScorePercent: (json['passingScorePercent'] as num?)?.toInt(),
      passed: json['passed'] as bool?,
      timeSpentMs: (json['timeSpentMs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AttemptSummaryToJson(AttemptSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientAttemptId': instance.clientAttemptId,
      'quizId': instance.quizId,
      'source': instance.source,
      'mode': instance.mode,
      'titleAr': instance.titleAr,
      'subjectId': instance.subjectId,
      'teacherTrackId': instance.teacherTrackId,
      'filters': instance.filters,
      'status': instance.status,
      'startedAt': instance.startedAt,
      'deadlineAt': instance.deadlineAt,
      'submittedAt': instance.submittedAt,
      'submittedLate': instance.submittedLate,
      'totalCount': instance.totalCount,
      'answeredCount': instance.answeredCount,
      'correctCount': instance.correctCount,
      'wrongCount': instance.wrongCount,
      'skippedCount': instance.skippedCount,
      'scorePercent': instance.scorePercent,
      'passingScorePercent': instance.passingScorePercent,
      'passed': instance.passed,
      'timeSpentMs': instance.timeSpentMs,
    };

const _$AttemptSummarySourceEnumMap = {
  AttemptSummarySource.curated: 'curated',
  AttemptSummarySource.random: 'random',
  AttemptSummarySource.mistakes: 'mistakes',
};

const _$AttemptSummaryModeEnumMap = {
  AttemptSummaryMode.practice: 'practice',
  AttemptSummaryMode.exam: 'exam',
};

const _$AttemptStatusEnumMap = {
  AttemptStatus.inProgress: 'in_progress',
  AttemptStatus.submitted: 'submitted',
  AttemptStatus.abandoned: 'abandoned',
};
