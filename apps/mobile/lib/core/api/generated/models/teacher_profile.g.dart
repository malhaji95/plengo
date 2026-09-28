// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeacherProfile _$TeacherProfileFromJson(Map<String, dynamic> json) =>
    TeacherProfile(
      teacher: TeacherDetail.fromJson(json['teacher'] as Map<String, dynamic>),
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => TeacherTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TeacherProfileToJson(TeacherProfile instance) =>
    <String, dynamic>{'teacher': instance.teacher, 'tracks': instance.tracks};
