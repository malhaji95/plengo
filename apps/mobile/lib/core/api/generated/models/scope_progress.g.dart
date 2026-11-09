// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scope_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScopeProgress _$ScopeProgressFromJson(Map<String, dynamic> json) =>
    ScopeProgress(
      questionsAttempted: (json['questionsAttempted'] as num).toInt(),
      questionsCorrect: (json['questionsCorrect'] as num).toInt(),
      questionsTotal: (json['questionsTotal'] as num).toInt(),
      quizzesCompleted: (json['quizzesCompleted'] as num).toInt(),
      quizzesTotal: (json['quizzesTotal'] as num).toInt(),
      flashcardsStudied: (json['flashcardsStudied'] as num).toInt(),
      flashcardsTotal: (json['flashcardsTotal'] as num).toInt(),
      completionPercent: (json['completionPercent'] as num).toInt(),
      subjectId: json['subjectId'] as String,
      teacherTrackId: json['teacherTrackId'] as String?,
      lastActivityAt: json['lastActivityAt'] as String?,
      units: (json['units'] as List<dynamic>)
          .map((e) => UnitProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
      lessons: (json['lessons'] as List<dynamic>)
          .map((e) => LessonProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ScopeProgressToJson(ScopeProgress instance) =>
    <String, dynamic>{
      'questionsAttempted': instance.questionsAttempted,
      'questionsCorrect': instance.questionsCorrect,
      'questionsTotal': instance.questionsTotal,
      'quizzesCompleted': instance.quizzesCompleted,
      'quizzesTotal': instance.quizzesTotal,
      'flashcardsStudied': instance.flashcardsStudied,
      'flashcardsTotal': instance.flashcardsTotal,
      'completionPercent': instance.completionPercent,
      'subjectId': instance.subjectId,
      'teacherTrackId': instance.teacherTrackId,
      'lastActivityAt': instance.lastActivityAt,
      'units': instance.units,
      'lessons': instance.lessons,
    };
