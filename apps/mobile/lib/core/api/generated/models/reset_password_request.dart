// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reset_password_request.g.dart';

@JsonSerializable()
class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.email,
    required this.otp,
    required this.newPassword,
  });
  
  factory ResetPasswordRequest.fromJson(Map<String, Object?> json) => _$ResetPasswordRequestFromJson(json);
  
  final String email;
  final String otp;
  final String newPassword;

  Map<String, Object?> toJson() => _$ResetPasswordRequestToJson(this);
}
