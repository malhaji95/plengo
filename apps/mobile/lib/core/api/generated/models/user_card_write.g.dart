// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_card_write.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserCardWrite _$UserCardWriteFromJson(Map<String, dynamic> json) => UserCardWrite(
  id: json['id'] as String,
  deckId: json['deckId'] as String,
  kind: $enumDecode(_$UserCardKindEnumMap, json['kind']),
  sortOrder: (json['sortOrder'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  frontText: json['frontText'] as String?,
  backText: json['backText'] as String?,
  frontMediaId: json['frontMediaId'] as String?,
  backMediaId: json['backMediaId'] as String?,
  officialFlashcardId: json['officialFlashcardId'] as String?,
  deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
);

Map<String, dynamic> _$UserCardWriteToJson(UserCardWrite instance) => <String, dynamic>{
  'id': instance.id,
  'deckId': instance.deckId,
  'kind': instance.kind,
  'frontText': ?instance.frontText,
  'backText': ?instance.backText,
  'frontMediaId': ?instance.frontMediaId,
  'backMediaId': ?instance.backMediaId,
  'officialFlashcardId': ?instance.officialFlashcardId,
  'sortOrder': instance.sortOrder,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'deletedAt': ?instance.deletedAt?.toIso8601String(),
};

const _$UserCardKindEnumMap = {UserCardKind.custom: 'custom', UserCardKind.officialRef: 'official_ref'};
