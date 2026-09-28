// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_deck_write.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDeckWrite _$UserDeckWriteFromJson(Map<String, dynamic> json) =>
    UserDeckWrite(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: (json['sortOrder'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      subjectId: json['subjectId'] as String?,
      color: json['color'] as String?,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );

Map<String, dynamic> _$UserDeckWriteToJson(UserDeckWrite instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'subjectId': ?instance.subjectId,
      'color': ?instance.color,
      'sortOrder': instance.sortOrder,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deletedAt': ?instance.deletedAt?.toIso8601String(),
    };
