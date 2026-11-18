// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plengo_deck_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlengoDeckListEnvelope _$PlengoDeckListEnvelopeFromJson(
  Map<String, dynamic> json,
) => PlengoDeckListEnvelope(
  success: json['success'] as bool,
  data: PlengoDeckList.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$PlengoDeckListEnvelopeToJson(
  PlengoDeckListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
