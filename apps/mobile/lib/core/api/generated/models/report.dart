// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'report_item_type.dart';
import 'report_reason.dart';
import 'report_status.dart';

part 'report.g.dart';

@JsonSerializable()
class Report {
  const Report({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.reason,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.resolvedAt,
  });
  
  factory Report.fromJson(Map<String, Object?> json) => _$ReportFromJson(json);
  
  final String id;
  final ReportItemType itemType;
  final String itemId;
  final ReportReason reason;
  @JsonKey(includeIfNull: true)
  final String? note;
  final ReportStatus status;
  final String createdAt;
  @JsonKey(includeIfNull: true)
  final String? resolvedAt;

  Map<String, Object?> toJson() => _$ReportToJson(this);
}
