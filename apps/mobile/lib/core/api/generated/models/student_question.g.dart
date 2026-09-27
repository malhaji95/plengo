// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentQuestion _$StudentQuestionFromJson(Map<String, dynamic> json) =>
    StudentQuestion(
      id: json['id'] as String,
      type: $enumDecode(_$StudentQuestionTypeEnumMap, json['type']),
      subjectId: json['subjectId'] as String,
      teacherTrackId: json['teacherTrackId'] as String?,
      unitId: json['unitId'] as String?,
      lessonId: json['lessonId'] as String?,
      sortOrder: json['sortOrder'] as num,
      difficulty: $enumDecodeNullable(
        _$StudentQuestionDifficultyEnumMap,
        json['difficulty'],
      ),
      isFree: json['isFree'] as bool,
      locked: json['locked'] as bool,
      questionText: json['questionText'] as String?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => StudentOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StudentQuestionToJson(StudentQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$StudentQuestionTypeEnumMap[instance.type]!,
      'subjectId': instance.subjectId,
      'teacherTrackId': instance.teacherTrackId,
      'unitId': instance.unitId,
      'lessonId': instance.lessonId,
      'sortOrder': instance.sortOrder,
      'difficulty': _$StudentQuestionDifficultyEnumMap[instance.difficulty],
      'isFree': instance.isFree,
      'locked': instance.locked,
      'questionText': instance.questionText,
      'options': instance.options,
    };

const _$StudentQuestionTypeEnumMap = {
  StudentQuestionType.mcq: 'mcq',
  StudentQuestionType.trueFalse: 'true_false',
  StudentQuestionType.written: 'written',
};

const _$StudentQuestionDifficultyEnumMap = {
  StudentQuestionDifficulty.easy: 'easy',
  StudentQuestionDifficulty.medium: 'medium',
  StudentQuestionDifficulty.hard: 'hard',
};
