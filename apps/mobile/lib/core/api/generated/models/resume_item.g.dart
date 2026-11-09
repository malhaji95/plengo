// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resume_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResumeItem _$ResumeItemFromJson(Map<String, dynamic> json) => ResumeItem(
  subjectId: json['subjectId'] as String,
  subjectNameAr: json['subjectNameAr'] as String,
  teacherTrackId: json['teacherTrackId'] as String?,
  trackTitleAr: json['trackTitleAr'] as String?,
  unitId: json['unitId'] as String?,
  unitNameAr: json['unitNameAr'] as String?,
  lessonId: json['lessonId'] as String?,
  lessonNameAr: json['lessonNameAr'] as String?,
  activityType: $enumDecode(
    _$ResumeItemActivityTypeEnumMap,
    json['activityType'],
  ),
  itemId: json['itemId'] as String?,
  itemTitleAr: json['itemTitleAr'] as String?,
  attemptId: json['attemptId'] as String?,
  lastActivityAt: json['lastActivityAt'] as String,
);

Map<String, dynamic> _$ResumeItemToJson(ResumeItem instance) =>
    <String, dynamic>{
      'subjectId': instance.subjectId,
      'subjectNameAr': instance.subjectNameAr,
      'teacherTrackId': instance.teacherTrackId,
      'trackTitleAr': instance.trackTitleAr,
      'unitId': instance.unitId,
      'unitNameAr': instance.unitNameAr,
      'lessonId': instance.lessonId,
      'lessonNameAr': instance.lessonNameAr,
      'activityType': instance.activityType,
      'itemId': instance.itemId,
      'itemTitleAr': instance.itemTitleAr,
      'attemptId': instance.attemptId,
      'lastActivityAt': instance.lastActivityAt,
    };

const _$ResumeItemActivityTypeEnumMap = {
  ResumeItemActivityType.question: 'question',
  ResumeItemActivityType.quiz: 'quiz',
  ResumeItemActivityType.deck: 'deck',
};
