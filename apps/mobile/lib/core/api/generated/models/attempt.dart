// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'attempt_question.dart';
import 'attempt_summary.dart';

part 'attempt.g.dart';

@JsonSerializable()
class Attempt {
  const Attempt({
    required this.attempt,
    required this.questions,
    required this.serverTime,
  });
  
  factory Attempt.fromJson(Map<String, Object?> json) => _$AttemptFromJson(json);
  
  final AttemptSummary attempt;
  final List<AttemptQuestion> questions;
  final String serverTime;

  Map<String, Object?> toJson() => _$AttemptToJson(this);
}
