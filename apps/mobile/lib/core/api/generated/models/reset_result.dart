// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reset_result.g.dart';

@JsonSerializable()
class ResetResult {
  const ResetResult({required this.reset});

  factory ResetResult.fromJson(Map<String, Object?> json) => _$ResetResultFromJson(json);

  final bool reset;

  Map<String, Object?> toJson() => _$ResetResultToJson(this);
}
