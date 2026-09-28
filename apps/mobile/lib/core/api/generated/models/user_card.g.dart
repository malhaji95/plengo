// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserCard _$UserCardFromJson(Map<String, dynamic> json) => UserCard(
  id: json['id'] as String,
  deckId: json['deckId'] as String,
  kind: $enumDecode(_$UserCardKindEnumMap, json['kind']),
  officialFlashcardId: json['officialFlashcardId'] as String?,
  locked: json['locked'] as bool,
  front: UserCardFace.fromJson(json['front'] as Map<String, dynamic>),
  back: UserCardFace.fromJson(json['back'] as Map<String, dynamic>),
  sortOrder: (json['sortOrder'] as num).toInt(),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
  deletedAt: json['deletedAt'] as String?,
);

Map<String, dynamic> _$UserCardToJson(UserCard instance) => <String, dynamic>{
  'id': instance.id,
  'deckId': instance.deckId,
  'kind': instance.kind,
  'officialFlashcardId': instance.officialFlashcardId,
  'locked': instance.locked,
  'front': instance.front,
  'back': instance.back,
  'sortOrder': instance.sortOrder,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'deletedAt': instance.deletedAt,
};

const _$UserCardKindEnumMap = {
  UserCardKind.custom: 'custom',
  UserCardKind.officialRef: 'official_ref',
};
