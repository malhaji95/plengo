// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'status.dart';

part 'results.g.dart';

@JsonSerializable()
class Results {
  const Results({
    required this.clientAttemptId,
    required this.status,
    required this.reason,
    required this.attemptId,
    required this.correctCount,
    required this.totalCount,
    required this.mismatches,
  });
  
  factory Results.fromJson(Map<String, Object?> json) => _$ResultsFromJson(json);
  
  final String clientAttemptId;
  final Status status;
  @JsonKey(includeIfNull: true)
  final String? reason;
  @JsonKey(includeIfNull: true)
  final String? attemptId;
  @JsonKey(includeIfNull: true)
  final int? correctCount;
  @JsonKey(includeIfNull: true)
  final int? totalCount;
  final int mismatches;

  Map<String, Object?> toJson() => _$ResultsToJson(this);
}
