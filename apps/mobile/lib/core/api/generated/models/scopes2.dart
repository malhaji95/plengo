// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'scope_type.dart';

part 'scopes2.g.dart';

@JsonSerializable()
class Scopes2 {
  const Scopes2({
    required this.scopeType,
    this.subjectId,
    this.teacherTrackId,
  });
  
  factory Scopes2.fromJson(Map<String, Object?> json) => _$Scopes2FromJson(json);
  
  final ScopeType scopeType;
  @JsonKey(includeIfNull: false)
  final String? subjectId;
  @JsonKey(includeIfNull: false)
  final String? teacherTrackId;

  Map<String, Object?> toJson() => _$Scopes2ToJson(this);
}
