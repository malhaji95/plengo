// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_scope_scope_type.dart';

part 'offline_scope.g.dart';

@JsonSerializable()
class OfflineScope {
  const OfflineScope({
    required this.scopeType,
    required this.subjectId,
    required this.teacherTrackId,
  });
  
  factory OfflineScope.fromJson(Map<String, Object?> json) => _$OfflineScopeFromJson(json);
  
  final OfflineScopeScopeType scopeType;
  @JsonKey(includeIfNull: true)
  final String? subjectId;
  @JsonKey(includeIfNull: true)
  final String? teacherTrackId;

  Map<String, Object?> toJson() => _$OfflineScopeToJson(this);
}
