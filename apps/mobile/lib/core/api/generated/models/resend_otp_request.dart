// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'resend_otp_request.g.dart';

@JsonSerializable()
class ResendOtpRequest {
  const ResendOtpRequest({
    required this.email,
  });
  
  factory ResendOtpRequest.fromJson(Map<String, Object?> json) => _$ResendOtpRequestFromJson(json);
  
  final String email;

  Map<String, Object?> toJson() => _$ResendOtpRequestToJson(this);
}
