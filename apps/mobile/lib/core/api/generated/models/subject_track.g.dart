// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectTrack _$SubjectTrackFromJson(Map<String, dynamic> json) => SubjectTrack(
  id: json['id'] as String,
  teacherId: json['teacherId'] as String,
  teacherNameAr: json['teacherNameAr'] as String,
  teacherPhotoUrl: json['teacherPhotoUrl'] as String?,
  titleAr: json['titleAr'] as String,
  description: json['description'] as String?,
  coverUrl: json['coverUrl'] as String?,
  hasAccess: json['hasAccess'] as bool,
);

Map<String, dynamic> _$SubjectTrackToJson(SubjectTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teacherId': instance.teacherId,
      'teacherNameAr': instance.teacherNameAr,
      'teacherPhotoUrl': instance.teacherPhotoUrl,
      'titleAr': instance.titleAr,
      'description': instance.description,
      'coverUrl': instance.coverUrl,
      'hasAccess': instance.hasAccess,
    };
