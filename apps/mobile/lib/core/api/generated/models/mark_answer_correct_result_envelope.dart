// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'mark_answer_correct_result.dart';

part 'mark_answer_correct_result_envelope.g.dart';

@JsonSerializable()
class MarkAnswerCorrectResultEnvelope {
  const MarkAnswerCorrectResultEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory MarkAnswerCorrectResultEnvelope.fromJson(Map<String, Object?> json) => _$MarkAnswerCorrectResultEnvelopeFromJson(json);
  
  final bool success;
  final MarkAnswerCorrectResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$MarkAnswerCorrectResultEnvelopeToJson(this);
}
