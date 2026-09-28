// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_quiz.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentQuiz _$StudentQuizFromJson(Map<String, dynamic> json) => StudentQuiz(
  id: json['id'] as String,
  subjectId: json['subjectId'] as String,
  teacherTrackId: json['teacherTrackId'] as String?,
  unitId: json['unitId'] as String?,
  lessonId: json['lessonId'] as String?,
  titleAr: json['titleAr'] as String,
  description: json['description'] as String?,
  allowedModes: $enumDecode(_$StudentQuizAllowedModesEnumMap, json['allowedModes']),
  timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt(),
  passingScorePercent: (json['passingScorePercent'] as num?)?.toInt(),
  maxAttempts: (json['maxAttempts'] as num?)?.toInt(),
  isMockExam: json['isMockExam'] as bool,
  allowOffline: json['allowOffline'] as bool,
  isFree: json['isFree'] as bool,
  sortOrder: (json['sortOrder'] as num).toInt(),
  contentVersion: (json['contentVersion'] as num).toInt(),
  totalCount: (json['totalCount'] as num).toInt(),
  accessibleCount: (json['accessibleCount'] as num).toInt(),
  lockedCount: (json['lockedCount'] as num).toInt(),
  locked: json['locked'] as bool,
  attemptsUsed: (json['attemptsUsed'] as num).toInt(),
  bestScorePercent: (json['bestScorePercent'] as num?)?.toInt(),
  inProgressAttemptId: json['inProgressAttemptId'] as String?,
);

Map<String, dynamic> _$StudentQuizToJson(StudentQuiz instance) => <String, dynamic>{
  'id': instance.id,
  'subjectId': instance.subjectId,
  'teacherTrackId': instance.teacherTrackId,
  'unitId': instance.unitId,
  'lessonId': instance.lessonId,
  'titleAr': instance.titleAr,
  'description': instance.description,
  'allowedModes': instance.allowedModes,
  'timeLimitSeconds': instance.timeLimitSeconds,
  'passingScorePercent': instance.passingScorePercent,
  'maxAttempts': instance.maxAttempts,
  'isMockExam': instance.isMockExam,
  'allowOffline': instance.allowOffline,
  'isFree': instance.isFree,
  'sortOrder': instance.sortOrder,
  'contentVersion': instance.contentVersion,
  'totalCount': instance.totalCount,
  'accessibleCount': instance.accessibleCount,
  'lockedCount': instance.lockedCount,
  'locked': instance.locked,
  'attemptsUsed': instance.attemptsUsed,
  'bestScorePercent': instance.bestScorePercent,
  'inProgressAttemptId': instance.inProgressAttemptId,
};

const _$StudentQuizAllowedModesEnumMap = {
  StudentQuizAllowedModes.practice: 'practice',
  StudentQuizAllowedModes.exam: 'exam',
  StudentQuizAllowedModes.both: 'both',
};
