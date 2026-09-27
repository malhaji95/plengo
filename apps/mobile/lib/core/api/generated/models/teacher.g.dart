// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Teacher _$TeacherFromJson(Map<String, dynamic> json) => Teacher(
  id: json['id'] as String,
  nameAr: json['nameAr'] as String,
  slug: json['slug'] as String,
  photoUrl: json['photoUrl'] as String?,
  shortDescription: json['shortDescription'] as String?,
  followerCount: json['followerCount'] as num,
  isFollowing: json['isFollowing'] as bool,
);

Map<String, dynamic> _$TeacherToJson(Teacher instance) => <String, dynamic>{
  'id': instance.id,
  'nameAr': instance.nameAr,
  'slug': instance.slug,
  'photoUrl': instance.photoUrl,
  'shortDescription': instance.shortDescription,
  'followerCount': instance.followerCount,
  'isFollowing': instance.isFollowing,
};
