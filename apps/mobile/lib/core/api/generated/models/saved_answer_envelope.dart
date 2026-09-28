// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'saved_answer.dart';

part 'saved_answer_envelope.g.dart';

@JsonSerializable()
class SavedAnswerEnvelope {
  const SavedAnswerEnvelope({required this.success, required this.data, required this.error});

  factory SavedAnswerEnvelope.fromJson(Map<String, Object?> json) => _$SavedAnswerEnvelopeFromJson(json);

  final bool success;
  final SavedAnswer data;
  final dynamic error;

  Map<String, Object?> toJson() => _$SavedAnswerEnvelopeToJson(this);
}
