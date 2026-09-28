// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_countdown.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExamCountdown _$ExamCountdownFromJson(Map<String, dynamic> json) => ExamCountdown(
  titleAr: json['titleAr'] as String,
  examDate: json['examDate'] as String,
  daysLeft: (json['daysLeft'] as num).toInt(),
);

Map<String, dynamic> _$ExamCountdownToJson(ExamCountdown instance) => <String, dynamic>{
  'titleAr': instance.titleAr,
  'examDate': instance.examDate,
  'daysLeft': instance.daysLeft,
};
