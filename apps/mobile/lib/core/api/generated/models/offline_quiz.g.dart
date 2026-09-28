// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_quiz.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineQuiz _$OfflineQuizFromJson(Map<String, dynamic> json) => OfflineQuiz(
  id: json['id'] as String,
  subjectId: json['subjectId'] as String,
  teacherTrackId: json['teacherTrackId'] as String?,
  unitId: json['unitId'] as String?,
  lessonId: json['lessonId'] as String?,
  titleAr: json['titleAr'] as String,
  description: json['description'] as String?,
  allowedModes: $enumDecode(
    _$OfflineQuizAllowedModesEnumMap,
    json['allowedModes'],
  ),
  timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt(),
  passingScore: (json['passingScore'] as num?)?.toInt(),
  shuffleQuestions: json['shuffleQuestions'] as bool,
  shuffleOptions: json['shuffleOptions'] as bool,
  isFree: json['isFree'] as bool,
  questionIds: (json['questionIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$OfflineQuizToJson(OfflineQuiz instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subjectId': instance.subjectId,
      'teacherTrackId': instance.teacherTrackId,
      'unitId': instance.unitId,
      'lessonId': instance.lessonId,
      'titleAr': instance.titleAr,
      'description': instance.description,
      'allowedModes': instance.allowedModes,
      'timeLimitSeconds': instance.timeLimitSeconds,
      'passingScore': instance.passingScore,
      'shuffleQuestions': instance.shuffleQuestions,
      'shuffleOptions': instance.shuffleOptions,
      'isFree': instance.isFree,
      'questionIds': instance.questionIds,
    };

const _$OfflineQuizAllowedModesEnumMap = {
  OfflineQuizAllowedModes.practice: 'practice',
  OfflineQuizAllowedModes.exam: 'exam',
  OfflineQuizAllowedModes.both: 'both',
};
