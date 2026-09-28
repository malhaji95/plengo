// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mistake.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mistake _$MistakeFromJson(Map<String, dynamic> json) => Mistake(
  questionId: json['questionId'] as String,
  type: $enumDecode(_$MistakeTypeEnumMap, json['type']),
  questionText: json['questionText'] as String,
  subjectId: json['subjectId'] as String,
  subjectNameAr: json['subjectNameAr'] as String,
  teacherTrackId: json['teacherTrackId'] as String?,
  trackTitleAr: json['trackTitleAr'] as String?,
  unitId: json['unitId'] as String?,
  unitNameAr: json['unitNameAr'] as String?,
  lessonId: json['lessonId'] as String?,
  lessonNameAr: json['lessonNameAr'] as String?,
  status: $enumDecode(_$MistakeStatusEnumMap, json['status']),
  wrongCount: (json['wrongCount'] as num).toInt(),
  correctStreak: (json['correctStreak'] as num).toInt(),
  firstWrongAt: json['firstWrongAt'] as String,
  lastWrongAt: json['lastWrongAt'] as String,
);

Map<String, dynamic> _$MistakeToJson(Mistake instance) => <String, dynamic>{
  'questionId': instance.questionId,
  'type': _$MistakeTypeEnumMap[instance.type]!,
  'questionText': instance.questionText,
  'subjectId': instance.subjectId,
  'subjectNameAr': instance.subjectNameAr,
  'teacherTrackId': instance.teacherTrackId,
  'trackTitleAr': instance.trackTitleAr,
  'unitId': instance.unitId,
  'unitNameAr': instance.unitNameAr,
  'lessonId': instance.lessonId,
  'lessonNameAr': instance.lessonNameAr,
  'status': _$MistakeStatusEnumMap[instance.status]!,
  'wrongCount': instance.wrongCount,
  'correctStreak': instance.correctStreak,
  'firstWrongAt': instance.firstWrongAt,
  'lastWrongAt': instance.lastWrongAt,
};

const _$MistakeTypeEnumMap = {
  MistakeType.mcq: 'mcq',
  MistakeType.trueFalse: 'true_false',
  MistakeType.written: 'written',
};

const _$MistakeStatusEnumMap = {
  MistakeStatus.active: 'active',
  MistakeStatus.mastered: 'mastered',
  MistakeStatus.removed: 'removed',
};
