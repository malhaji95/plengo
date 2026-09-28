// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineItem _$OfflineItemFromJson(Map<String, dynamic> json) => OfflineItem(
  type: $enumDecode(_$OfflineItemTypeEnumMap, json['type']),
  id: json['id'] as String,
  version: (json['version'] as num).toInt(),
  question: json['question'] == null ? null : OfflineQuestion.fromJson(json['question'] as Map<String, dynamic>),
  deck: json['deck'] == null ? null : OfflineDeck.fromJson(json['deck'] as Map<String, dynamic>),
  card: json['card'] == null ? null : OfflineCard.fromJson(json['card'] as Map<String, dynamic>),
  quiz: json['quiz'] == null ? null : OfflineQuiz.fromJson(json['quiz'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OfflineItemToJson(OfflineItem instance) => <String, dynamic>{
  'type': instance.type,
  'id': instance.id,
  'version': instance.version,
  'question': instance.question,
  'deck': instance.deck,
  'card': instance.card,
  'quiz': instance.quiz,
};

const _$OfflineItemTypeEnumMap = {
  OfflineItemType.question: 'question',
  OfflineItemType.deck: 'deck',
  OfflineItemType.card: 'card',
  OfflineItemType.quiz: 'quiz',
};
