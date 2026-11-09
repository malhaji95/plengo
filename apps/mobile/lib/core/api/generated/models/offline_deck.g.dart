// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_deck.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineDeck _$OfflineDeckFromJson(Map<String, dynamic> json) => OfflineDeck(
  id: json['id'] as String,
  subjectId: json['subjectId'] as String,
  teacherTrackId: json['teacherTrackId'] as String?,
  unitId: json['unitId'] as String?,
  lessonId: json['lessonId'] as String?,
  titleAr: json['titleAr'] as String,
  description: json['description'] as String?,
  isFree: json['isFree'] as bool,
  sortOrder: (json['sortOrder'] as num).toInt(),
  cardIds: (json['cardIds'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$OfflineDeckToJson(OfflineDeck instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subjectId': instance.subjectId,
      'teacherTrackId': instance.teacherTrackId,
      'unitId': instance.unitId,
      'lessonId': instance.lessonId,
      'titleAr': instance.titleAr,
      'description': instance.description,
      'isFree': instance.isFree,
      'sortOrder': instance.sortOrder,
      'cardIds': instance.cardIds,
    };
