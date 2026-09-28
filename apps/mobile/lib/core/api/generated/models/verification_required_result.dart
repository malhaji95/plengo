// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'verification_required_result.g.dart';

@JsonSerializable()
class VerificationRequiredResult {
  const VerificationRequiredResult({
    required this.verificationRequired,
  });
  
  factory VerificationRequiredResult.fromJson(Map<String, Object?> json) => _$VerificationRequiredResultFromJson(json);
  
  final bool verificationRequired;

  Map<String, Object?> toJson() => _$VerificationRequiredResultToJson(this);
}
