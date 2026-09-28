// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'mobile_logout_request.g.dart';

@JsonSerializable()
class MobileLogoutRequest {
  const MobileLogoutRequest({required this.refreshToken});

  factory MobileLogoutRequest.fromJson(Map<String, Object?> json) => _$MobileLogoutRequestFromJson(json);

  final String refreshToken;

  Map<String, Object?> toJson() => _$MobileLogoutRequestToJson(this);
}
