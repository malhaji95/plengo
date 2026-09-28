// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'offline_accepted_answer.g.dart';

@JsonSerializable()
class OfflineAcceptedAnswer {
  const OfflineAcceptedAnswer({
    required this.original,
    required this.normalized,
    required this.normalizationVersion,
  });
  
  factory OfflineAcceptedAnswer.fromJson(Map<String, Object?> json) => _$OfflineAcceptedAnswerFromJson(json);
  
  final String original;
  final String normalized;
  final int normalizationVersion;

  Map<String, Object?> toJson() => _$OfflineAcceptedAnswerToJson(this);
}
