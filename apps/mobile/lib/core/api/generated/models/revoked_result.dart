// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'revoked_result.g.dart';

@JsonSerializable()
class RevokedResult {
  const RevokedResult({
    required this.revoked,
  });
  
  factory RevokedResult.fromJson(Map<String, Object?> json) => _$RevokedResultFromJson(json);
  
  final bool revoked;

  Map<String, Object?> toJson() => _$RevokedResultToJson(this);
}
