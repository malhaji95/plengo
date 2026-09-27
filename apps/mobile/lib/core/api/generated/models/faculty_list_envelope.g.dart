// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faculty_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FacultyListEnvelope _$FacultyListEnvelopeFromJson(Map<String, dynamic> json) =>
    FacultyListEnvelope(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => Faculty.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'],
    );

Map<String, dynamic> _$FacultyListEnvelopeToJson(
  FacultyListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
