// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineCard _$OfflineCardFromJson(Map<String, dynamic> json) => OfflineCard(
  id: json['id'] as String,
  deckId: json['deckId'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
  front: OfflineImage.fromJson(json['front'] as Map<String, dynamic>),
  back: OfflineImage.fromJson(json['back'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OfflineCardToJson(OfflineCard instance) => <String, dynamic>{
  'id': instance.id,
  'deckId': instance.deckId,
  'sortOrder': instance.sortOrder,
  'front': instance.front,
  'back': instance.back,
};
