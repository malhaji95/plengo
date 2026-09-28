// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'review_log.dart';
import 'srs_sync_state.dart';

part 'srs_sync_request.g.dart';

@JsonSerializable()
class SrsSyncRequest {
  const SrsSyncRequest({
    required this.logs,
    required this.states,
  });
  
  factory SrsSyncRequest.fromJson(Map<String, Object?> json) => _$SrsSyncRequestFromJson(json);
  
  final List<ReviewLog> logs;
  final List<SrsSyncState> states;

  Map<String, Object?> toJson() => _$SrsSyncRequestToJson(this);
}
