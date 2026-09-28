// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'revoke_push_token_request.g.dart';

@JsonSerializable()
class RevokePushTokenRequest {
  const RevokePushTokenRequest({
    required this.token,
  });
  
  factory RevokePushTokenRequest.fromJson(Map<String, Object?> json) => _$RevokePushTokenRequestFromJson(json);
  
  final String token;

  Map<String, Object?> toJson() => _$RevokePushTokenRequestToJson(this);
}
