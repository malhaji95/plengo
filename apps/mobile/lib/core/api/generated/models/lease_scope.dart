// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lease_scope_scope_type.dart';

part 'lease_scope.g.dart';

@JsonSerializable()
class LeaseScope {
  const LeaseScope({required this.scopeType, this.subjectId, this.teacherTrackId});

  factory LeaseScope.fromJson(Map<String, Object?> json) => _$LeaseScopeFromJson(json);

  final LeaseScopeScopeType scopeType;
  @JsonKey(includeIfNull: false)
  final String? subjectId;
  @JsonKey(includeIfNull: false)
  final String? teacherTrackId;

  Map<String, Object?> toJson() => _$LeaseScopeToJson(this);
}
