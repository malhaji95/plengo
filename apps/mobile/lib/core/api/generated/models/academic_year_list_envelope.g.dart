// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academic_year_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcademicYearListEnvelope _$AcademicYearListEnvelopeFromJson(
  Map<String, dynamic> json,
) => AcademicYearListEnvelope(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>)
      .map((e) => AcademicYear.fromJson(e as Map<String, dynamic>))
      .toList(),
  error: json['error'],
);

Map<String, dynamic> _$AcademicYearListEnvelopeToJson(
  AcademicYearListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
