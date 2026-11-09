// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'push_token_request_platform.dart';

part 'push_token_request.g.dart';

@JsonSerializable()
class PushTokenRequest {
  const PushTokenRequest({
    required this.token,
    required this.platform,
    this.appVersion,
  });
  
  factory PushTokenRequest.fromJson(Map<String, Object?> json) => _$PushTokenRequestFromJson(json);
  
  final String token;
  final PushTokenRequestPlatform platform;
  @JsonKey(includeIfNull: false)
  final String? appVersion;

  Map<String, Object?> toJson() => _$PushTokenRequestToJson(this);
}
