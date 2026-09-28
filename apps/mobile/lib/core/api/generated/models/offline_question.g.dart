// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineQuestion _$OfflineQuestionFromJson(Map<String, dynamic> json) =>
    OfflineQuestion(
      id: json['id'] as String,
      type: $enumDecode(_$OfflineQuestionTypeEnumMap, json['type']),
      subjectId: json['subjectId'] as String,
      teacherTrackId: json['teacherTrackId'] as String?,
      unitId: json['unitId'] as String?,
      lessonId: json['lessonId'] as String?,
      sortOrder: (json['sortOrder'] as num).toInt(),
      difficulty: $enumDecodeNullable(
        _$OfflineQuestionDifficultyEnumMap,
        json['difficulty'],
      ),
      isFree: json['isFree'] as bool,
      questionText: json['questionText'] as String,
      explanation: json['explanation'] as String?,
      options: (json['options'] as List<dynamic>)
          .map((e) => Options.fromJson(e as Map<String, dynamic>))
          .toList(),
      acceptedAnswers: (json['acceptedAnswers'] as List<dynamic>)
          .map((e) => AcceptedAnswers.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OfflineQuestionToJson(OfflineQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'subjectId': instance.subjectId,
      'teacherTrackId': instance.teacherTrackId,
      'unitId': instance.unitId,
      'lessonId': instance.lessonId,
      'sortOrder': instance.sortOrder,
      'difficulty': instance.difficulty,
      'isFree': instance.isFree,
      'questionText': instance.questionText,
      'explanation': instance.explanation,
      'options': instance.options,
      'acceptedAnswers': instance.acceptedAnswers,
    };

const _$OfflineQuestionTypeEnumMap = {
  OfflineQuestionType.mcq: 'mcq',
  OfflineQuestionType.trueFalse: 'true_false',
  OfflineQuestionType.written: 'written',
};

const _$OfflineQuestionDifficultyEnumMap = {
  OfflineQuestionDifficulty.easy: 'easy',
  OfflineQuestionDifficulty.medium: 'medium',
  OfflineQuestionDifficulty.hard: 'hard',
};
