// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_attempt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineAttempt _$OfflineAttemptFromJson(Map<String, dynamic> json) =>
    OfflineAttempt(
      clientAttemptId: json['clientAttemptId'] as String,
      source: $enumDecode(_$OfflineAttemptSourceEnumMap, json['source']),
      mode: $enumDecode(_$OfflineAttemptModeEnumMap, json['mode']),
      questionIds: (json['questionIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      answers: (json['answers'] as List<dynamic>)
          .map((e) => OfflineAnswer.fromJson(e as Map<String, dynamic>))
          .toList(),
      quizId: json['quizId'] as String?,
      subjectId: json['subjectId'] as String?,
      teacherTrackId: json['teacherTrackId'] as String?,
      timeSpentMs: (json['timeSpentMs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$OfflineAttemptToJson(OfflineAttempt instance) =>
    <String, dynamic>{
      'clientAttemptId': instance.clientAttemptId,
      'source': instance.source,
      'mode': instance.mode,
      'quizId': ?instance.quizId,
      'subjectId': ?instance.subjectId,
      'teacherTrackId': ?instance.teacherTrackId,
      'questionIds': instance.questionIds,
      'startedAt': instance.startedAt.toIso8601String(),
      'submittedAt': instance.submittedAt.toIso8601String(),
      'timeSpentMs': ?instance.timeSpentMs,
      'answers': instance.answers,
    };

const _$OfflineAttemptSourceEnumMap = {
  OfflineAttemptSource.curated: 'curated',
  OfflineAttemptSource.random: 'random',
  OfflineAttemptSource.mistakes: 'mistakes',
};

const _$OfflineAttemptModeEnumMap = {
  OfflineAttemptMode.practice: 'practice',
  OfflineAttemptMode.exam: 'exam',
};
