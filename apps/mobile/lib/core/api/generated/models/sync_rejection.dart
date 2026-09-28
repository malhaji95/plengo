// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'sync_rejection_code.dart';
import 'sync_rejection_type.dart';

part 'sync_rejection.g.dart';

@JsonSerializable()
class SyncRejection {
  const SyncRejection({required this.type, required this.id, required this.code, required this.reason});

  factory SyncRejection.fromJson(Map<String, Object?> json) => _$SyncRejectionFromJson(json);

  final SyncRejectionType type;
  final String id;
  final SyncRejectionCode code;
  final String reason;

  Map<String, Object?> toJson() => _$SyncRejectionToJson(this);
}
