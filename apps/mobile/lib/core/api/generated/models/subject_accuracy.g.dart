// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_accuracy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectAccuracy _$SubjectAccuracyFromJson(Map<String, dynamic> json) => SubjectAccuracy(
  answered: (json['answered'] as num).toInt(),
  correct: (json['correct'] as num).toInt(),
  accuracyPercent: (json['accuracyPercent'] as num?)?.toInt(),
  subjectId: json['subjectId'] as String,
  subjectNameAr: json['subjectNameAr'] as String,
  teacherTrackId: json['teacherTrackId'] as String?,
  trackTitleAr: json['trackTitleAr'] as String?,
);

Map<String, dynamic> _$SubjectAccuracyToJson(SubjectAccuracy instance) => <String, dynamic>{
  'answered': instance.answered,
  'correct': instance.correct,
  'accuracyPercent': instance.accuracyPercent,
  'subjectId': instance.subjectId,
  'subjectNameAr': instance.subjectNameAr,
  'teacherTrackId': instance.teacherTrackId,
  'trackTitleAr': instance.trackTitleAr,
};
