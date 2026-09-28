// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'srs_card_state.dart';

part 'srs_sync_result.g.dart';

@JsonSerializable()
class SrsSyncResult {
  const SrsSyncResult({required this.acceptedLogs, required this.appliedStates, required this.states});

  factory SrsSyncResult.fromJson(Map<String, Object?> json) => _$SrsSyncResultFromJson(json);

  final int acceptedLogs;
  final int appliedStates;
  final List<SrsCardState> states;

  Map<String, Object?> toJson() => _$SrsSyncResultToJson(this);
}
