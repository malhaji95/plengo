// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'teacher_detail.g.dart';

@JsonSerializable()
class TeacherDetail {
  const TeacherDetail({
    required this.id,
    required this.nameAr,
    required this.slug,
    required this.photoUrl,
    required this.shortDescription,
    required this.followerCount,
    required this.isFollowing,
    required this.bio,
  });

  factory TeacherDetail.fromJson(Map<String, Object?> json) => _$TeacherDetailFromJson(json);

  final String id;
  final String nameAr;
  final String slug;
  @JsonKey(includeIfNull: true)
  final String? photoUrl;
  @JsonKey(includeIfNull: true)
  final String? shortDescription;
  final num followerCount;
  final bool isFollowing;
  @JsonKey(includeIfNull: true)
  final String? bio;

  Map<String, Object?> toJson() => _$TeacherDetailToJson(this);
}
