// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'password_confirm_request.g.dart';

@JsonSerializable()
class PasswordConfirmRequest {
  const PasswordConfirmRequest({required this.password});

  factory PasswordConfirmRequest.fromJson(Map<String, Object?> json) => _$PasswordConfirmRequestFromJson(json);

  final String password;

  Map<String, Object?> toJson() => _$PasswordConfirmRequestToJson(this);
}
