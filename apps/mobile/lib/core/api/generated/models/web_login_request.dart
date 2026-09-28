// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'web_login_request.g.dart';

@JsonSerializable()
class WebLoginRequest {
  const WebLoginRequest({required this.email, required this.password});

  factory WebLoginRequest.fromJson(Map<String, Object?> json) => _$WebLoginRequestFromJson(json);

  final String email;
  final String password;

  Map<String, Object?> toJson() => _$WebLoginRequestToJson(this);
}
