// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeacherTrack _$TeacherTrackFromJson(Map<String, dynamic> json) => TeacherTrack(
  id: json['id'] as String,
  teacherId: json['teacherId'] as String,
  teacherNameAr: json['teacherNameAr'] as String,
  subjectId: json['subjectId'] as String,
  subjectNameAr: json['subjectNameAr'] as String,
  educationLevelId: json['educationLevelId'] as String,
  titleAr: json['titleAr'] as String,
  slug: json['slug'] as String,
  description: json['description'] as String?,
  coverUrl: json['coverUrl'] as String?,
);

Map<String, dynamic> _$TeacherTrackToJson(TeacherTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacherId': instance.teacherId,
      'teacherNameAr': instance.teacherNameAr,
      'subjectId': instance.subjectId,
      'subjectNameAr': instance.subjectNameAr,
      'educationLevelId': instance.educationLevelId,
      'titleAr': instance.titleAr,
      'slug': instance.slug,
      'description': instance.description,
      'coverUrl': instance.coverUrl,
    };
