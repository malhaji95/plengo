// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'items2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Items2 _$Items2FromJson(Map<String, dynamic> json) => Items2(
  type: $enumDecode(_$OfflineItemTypeEnumMap, json['type']),
  id: json['id'] as String,
  version: (json['version'] as num).toInt(),
);

Map<String, dynamic> _$Items2ToJson(Items2 instance) => <String, dynamic>{
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
