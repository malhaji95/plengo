// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'check_result.dart';

part 'check_result_envelope.g.dart';

@JsonSerializable()
class CheckResultEnvelope {
  const CheckResultEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory CheckResultEnvelope.fromJson(Map<String, Object?> json) => _$CheckResultEnvelopeFromJson(json);
  
  final bool success;
  final CheckResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$CheckResultEnvelopeToJson(this);
}
