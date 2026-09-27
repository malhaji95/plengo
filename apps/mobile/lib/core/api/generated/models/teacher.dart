// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'teacher.g.dart';

@JsonSerializable()
class Teacher {
  const Teacher({
    required this.id,
    required this.nameAr,
    required this.slug,
    required this.photoUrl,
    required this.shortDescription,
    required this.followerCount,
    required this.isFollowing,
  });
  
  factory Teacher.fromJson(Map<String, Object?> json) => _$TeacherFromJson(json);
  
  final String id;
  final String nameAr;
  final String slug;
  @JsonKey(includeIfNull: true)
  final String? photoUrl;
  @JsonKey(includeIfNull: true)
  final String? shortDescription;
  final num followerCount;
  final bool isFollowing;

  Map<String, Object?> toJson() => _$TeacherToJson(this);
}
