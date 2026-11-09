// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_items_page_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineItemsPageEnvelope _$OfflineItemsPageEnvelopeFromJson(
  Map<String, dynamic> json,
) => OfflineItemsPageEnvelope(
  success: json['success'] as bool,
  data: OfflineItemsPage.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$OfflineItemsPageEnvelopeToJson(
  OfflineItemsPageEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
