// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_pair_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenPairEnvelope _$TokenPairEnvelopeFromJson(Map<String, dynamic> json) =>
    TokenPairEnvelope(
      success: json['success'] as bool,
      data: TokenPair.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$TokenPairEnvelopeToJson(TokenPairEnvelope instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };
