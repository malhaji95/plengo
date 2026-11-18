// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_student_loyalty_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminStudentLoyaltyEnvelope _$AdminStudentLoyaltyEnvelopeFromJson(
  Map<String, dynamic> json,
) => AdminStudentLoyaltyEnvelope(
  success: json['success'] as bool,
  data: AdminStudentLoyalty.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$AdminStudentLoyaltyEnvelopeToJson(
  AdminStudentLoyaltyEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
