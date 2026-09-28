// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'verify_email_request.g.dart';

@JsonSerializable()
class VerifyEmailRequest {
  const VerifyEmailRequest({required this.email, required this.otp});

  factory VerifyEmailRequest.fromJson(Map<String, Object?> json) => _$VerifyEmailRequestFromJson(json);

  final String email;
  final String otp;

  Map<String, Object?> toJson() => _$VerifyEmailRequestToJson(this);
}
