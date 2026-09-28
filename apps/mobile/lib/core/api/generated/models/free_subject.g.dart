// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'free_subject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FreeSubject _$FreeSubjectFromJson(Map<String, dynamic> json) => FreeSubject(
  subjectId: json['subjectId'] as String,
  nameAr: json['nameAr'] as String,
  freeCount: (json['freeCount'] as num).toInt(),
);

Map<String, dynamic> _$FreeSubjectToJson(FreeSubject instance) => <String, dynamic>{
  'subjectId': instance.subjectId,
  'nameAr': instance.nameAr,
  'freeCount': instance.freeCount,
};
