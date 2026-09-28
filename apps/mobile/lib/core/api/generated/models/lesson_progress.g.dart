// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonProgress _$LessonProgressFromJson(Map<String, dynamic> json) =>
    LessonProgress(
      questionsAttempted: (json['questionsAttempted'] as num).toInt(),
      questionsCorrect: (json['questionsCorrect'] as num).toInt(),
      questionsTotal: (json['questionsTotal'] as num).toInt(),
      quizzesCompleted: (json['quizzesCompleted'] as num).toInt(),
      quizzesTotal: (json['quizzesTotal'] as num).toInt(),
      flashcardsStudied: (json['flashcardsStudied'] as num).toInt(),
      flashcardsTotal: (json['flashcardsTotal'] as num).toInt(),
      completionPercent: (json['completionPercent'] as num).toInt(),
      lessonId: json['lessonId'] as String,
    );

Map<String, dynamic> _$LessonProgressToJson(LessonProgress instance) =>
    <String, dynamic>{
      'questionsAttempted': instance.questionsAttempted,
      'questionsCorrect': instance.questionsCorrect,
      'questionsTotal': instance.questionsTotal,
      'quizzesCompleted': instance.quizzesCompleted,
      'quizzesTotal': instance.quizzesTotal,
      'flashcardsStudied': instance.flashcardsStudied,
      'flashcardsTotal': instance.flashcardsTotal,
      'completionPercent': instance.completionPercent,
      'lessonId': instance.lessonId,
    };
