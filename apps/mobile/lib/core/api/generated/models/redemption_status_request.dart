// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'redemption_status_request_status.dart';

part 'redemption_status_request.g.dart';

@JsonSerializable()
class RedemptionStatusRequest {
  const RedemptionStatusRequest({
    required this.status,
    this.note,
  });
  
  factory RedemptionStatusRequest.fromJson(Map<String, Object?> json) => _$RedemptionStatusRequestFromJson(json);
  
  final RedemptionStatusRequestStatus status;
  @JsonKey(includeIfNull: false)
  final String? note;

  Map<String, Object?> toJson() => _$RedemptionStatusRequestToJson(this);
}
