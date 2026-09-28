// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_accuracy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonAccuracy _$LessonAccuracyFromJson(Map<String, dynamic> json) =>
    LessonAccuracy(
      answered: (json['answered'] as num).toInt(),
      correct: (json['correct'] as num).toInt(),
      accuracyPercent: (json['accuracyPercent'] as num?)?.toInt(),
      lessonId: json['lessonId'] as String,
      lessonNameAr: json['lessonNameAr'] as String,
    );

Map<String, dynamic> _$LessonAccuracyToJson(LessonAccuracy instance) =>
    <String, dynamic>{
      'answered': instance.answered,
      'correct': instance.correct,
      'accuracyPercent': instance.accuracyPercent,
      'lessonId': instance.lessonId,
      'lessonNameAr': instance.lessonNameAr,
    };
