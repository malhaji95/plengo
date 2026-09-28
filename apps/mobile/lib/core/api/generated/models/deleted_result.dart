// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'deleted_result.g.dart';

@JsonSerializable()
class DeletedResult {
  const DeletedResult({required this.deleted});

  factory DeletedResult.fromJson(Map<String, Object?> json) => _$DeletedResultFromJson(json);

  final bool deleted;

  Map<String, Object?> toJson() => _$DeletedResultToJson(this);
}
