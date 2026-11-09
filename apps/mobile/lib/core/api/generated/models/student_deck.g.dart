// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_deck.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentDeck _$StudentDeckFromJson(Map<String, dynamic> json) => StudentDeck(
  id: json['id'] as String,
  subjectId: json['subjectId'] as String,
  teacherTrackId: json['teacherTrackId'] as String?,
  unitId: json['unitId'] as String?,
  lessonId: json['lessonId'] as String?,
  titleAr: json['titleAr'] as String,
  description: json['description'] as String?,
  coverUrl: json['coverUrl'] as String?,
  cardCount: (json['cardCount'] as num).toInt(),
  isFree: json['isFree'] as bool,
  locked: json['locked'] as bool,
  contentVersion: (json['contentVersion'] as num).toInt(),
  sortOrder: (json['sortOrder'] as num).toInt(),
);

Map<String, dynamic> _$StudentDeckToJson(StudentDeck instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subjectId': instance.subjectId,
      'teacherTrackId': instance.teacherTrackId,
      'unitId': instance.unitId,
      'lessonId': instance.lessonId,
      'titleAr': instance.titleAr,
      'description': instance.description,
      'coverUrl': instance.coverUrl,
      'cardCount': instance.cardCount,
      'isFree': instance.isFree,
      'locked': instance.locked,
      'contentVersion': instance.contentVersion,
      'sortOrder': instance.sortOrder,
    };
