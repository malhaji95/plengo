// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackDetail _$TrackDetailFromJson(Map<String, dynamic> json) => TrackDetail(
  track: TeacherTrack.fromJson(json['track'] as Map<String, dynamic>),
  teacher: Teacher.fromJson(json['teacher'] as Map<String, dynamic>),
  subject: Subject.fromJson(json['subject'] as Map<String, dynamic>),
  access: ScopeAccess.fromJson(json['access'] as Map<String, dynamic>),
  questionCount: ContentCount.fromJson(
    json['questionCount'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$TrackDetailToJson(TrackDetail instance) =>
    <String, dynamic>{
      'track': instance.track,
      'teacher': instance.teacher,
      'subject': instance.subject,
      'access': instance.access,
      'questionCount': instance.questionCount,
    };
