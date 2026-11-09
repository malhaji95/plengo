// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeacherDetail _$TeacherDetailFromJson(Map<String, dynamic> json) =>
    TeacherDetail(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String,
      slug: json['slug'] as String,
      photoUrl: json['photoUrl'] as String?,
      shortDescription: json['shortDescription'] as String?,
      followerCount: json['followerCount'] as num,
      isFollowing: json['isFollowing'] as bool,
      bio: json['bio'] as String?,
    );

Map<String, dynamic> _$TeacherDetailToJson(TeacherDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nameAr': instance.nameAr,
      'slug': instance.slug,
      'photoUrl': instance.photoUrl,
      'shortDescription': instance.shortDescription,
      'followerCount': instance.followerCount,
      'isFollowing': instance.isFollowing,
      'bio': instance.bio,
    };
