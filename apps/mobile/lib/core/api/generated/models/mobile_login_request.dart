// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'mobile_login_request_platform.dart';

part 'mobile_login_request.g.dart';

@JsonSerializable()
class MobileLoginRequest {
  const MobileLoginRequest({
    required this.email,
    required this.password,
    required this.platform,
    this.appVersion,
  });
  
  factory MobileLoginRequest.fromJson(Map<String, Object?> json) => _$MobileLoginRequestFromJson(json);
  
  final String email;
  final String password;
  final MobileLoginRequestPlatform platform;
  @JsonKey(includeIfNull: false)
  final String? appVersion;

  Map<String, Object?> toJson() => _$MobileLoginRequestToJson(this);
}
