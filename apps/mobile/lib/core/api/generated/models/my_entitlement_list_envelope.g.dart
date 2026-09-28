// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_entitlement_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyEntitlementListEnvelope _$MyEntitlementListEnvelopeFromJson(Map<String, dynamic> json) => MyEntitlementListEnvelope(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>).map((e) => MyEntitlement.fromJson(e as Map<String, dynamic>)).toList(),
  error: json['error'],
);

Map<String, dynamic> _$MyEntitlementListEnvelopeToJson(MyEntitlementListEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
