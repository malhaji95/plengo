// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'srs_states_page_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SrsStatesPageEnvelope _$SrsStatesPageEnvelopeFromJson(Map<String, dynamic> json) => SrsStatesPageEnvelope(
  success: json['success'] as bool,
  data: SrsStatesPage.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$SrsStatesPageEnvelopeToJson(SrsStatesPageEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
