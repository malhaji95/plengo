// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'report_item_type.dart';
import 'report_reason.dart';

part 'create_report_request.g.dart';

@JsonSerializable()
class CreateReportRequest {
  const CreateReportRequest({required this.itemType, required this.itemId, required this.reason, this.note});

  factory CreateReportRequest.fromJson(Map<String, Object?> json) => _$CreateReportRequestFromJson(json);

  final ReportItemType itemType;
  final String itemId;
  final ReportReason reason;
  @JsonKey(includeIfNull: false)
  final String? note;

  Map<String, Object?> toJson() => _$CreateReportRequestToJson(this);
}
