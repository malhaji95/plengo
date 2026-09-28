// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'accepted_answers.g.dart';

@JsonSerializable()
class AcceptedAnswers {
  const AcceptedAnswers({
    required this.original,
    required this.normalized,
    required this.normalizationVersion,
  });
  
  factory AcceptedAnswers.fromJson(Map<String, Object?> json) => _$AcceptedAnswersFromJson(json);
  
  final String original;
  final String normalized;
  final int normalizationVersion;

  Map<String, Object?> toJson() => _$AcceptedAnswersToJson(this);
}
