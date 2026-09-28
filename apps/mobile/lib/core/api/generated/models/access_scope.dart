// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'access_scope_scope_type.dart';

part 'access_scope.g.dart';

@JsonSerializable()
class AccessScope {
  const AccessScope({
    required this.scopeType,
    required this.subjectId,
    required this.teacherTrackId,
    required this.subjectNameAr,
    required this.trackTitleAr,
    required this.teacherNameAr,
    required this.educationLevelId,
  });

  factory AccessScope.fromJson(Map<String, Object?> json) => _$AccessScopeFromJson(json);

  final AccessScopeScopeType scopeType;
  final String subjectId;
  @JsonKey(includeIfNull: true)
  final String? teacherTrackId;
  final String subjectNameAr;
  @JsonKey(includeIfNull: true)
  final String? trackTitleAr;
  @JsonKey(includeIfNull: true)
  final String? teacherNameAr;
  final String educationLevelId;

  Map<String, Object?> toJson() => _$AccessScopeToJson(this);
}
