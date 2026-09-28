// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_manifest_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineManifestItem _$OfflineManifestItemFromJson(Map<String, dynamic> json) => OfflineManifestItem(
  type: $enumDecode(_$OfflineItemTypeEnumMap, json['type']),
  id: json['id'] as String,
  version: (json['version'] as num).toInt(),
);

Map<String, dynamic> _$OfflineManifestItemToJson(OfflineManifestItem instance) => <String, dynamic>{
  'type': instance.type,
  'id': instance.id,
  'version': instance.version,
};

const _$OfflineItemTypeEnumMap = {
  OfflineItemType.question: 'question',
  OfflineItemType.deck: 'deck',
  OfflineItemType.card: 'card',
  OfflineItemType.quiz: 'quiz',
};
