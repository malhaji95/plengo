// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'attempt_filters.dart';
import 'start_attempt_request_mode.dart';
import 'start_attempt_request_source.dart';

part 'start_attempt_request.g.dart';

@JsonSerializable()
class StartAttemptRequest {
  const StartAttemptRequest({
    required this.clientAttemptId,
    required this.source,
    required this.mode,
    this.quizId,
    this.filters,
  });
  
  factory StartAttemptRequest.fromJson(Map<String, Object?> json) => _$StartAttemptRequestFromJson(json);
  
  final String clientAttemptId;
  final StartAttemptRequestSource source;
  final StartAttemptRequestMode mode;
  @JsonKey(includeIfNull: false)
  final String? quizId;
  @JsonKey(includeIfNull: false)
  final AttemptFilters? filters;

  Map<String, Object?> toJson() => _$StartAttemptRequestToJson(this);
}
