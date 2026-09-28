// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'verified_result.g.dart';

@JsonSerializable()
class VerifiedResult {
  const VerifiedResult({required this.verified});

  factory VerifiedResult.fromJson(Map<String, Object?> json) => _$VerifiedResultFromJson(json);

  final bool verified;

  Map<String, Object?> toJson() => _$VerifiedResultToJson(this);
}
