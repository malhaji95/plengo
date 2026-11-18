// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'admin_student_loyalty.dart';

part 'admin_student_loyalty_envelope.g.dart';

@JsonSerializable()
class AdminStudentLoyaltyEnvelope {
  const AdminStudentLoyaltyEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory AdminStudentLoyaltyEnvelope.fromJson(Map<String, Object?> json) => _$AdminStudentLoyaltyEnvelopeFromJson(json);
  
  final bool success;
  final AdminStudentLoyalty data;
  final dynamic error;

  Map<String, Object?> toJson() => _$AdminStudentLoyaltyEnvelopeToJson(this);
}
