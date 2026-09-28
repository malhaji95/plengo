// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_deck.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDeck _$UserDeckFromJson(Map<String, dynamic> json) => UserDeck(
  id: json['id'] as String,
  name: json['name'] as String,
  subjectId: json['subjectId'] as String?,
  color: json['color'] as String?,
  sortOrder: (json['sortOrder'] as num).toInt(),
  cardCount: (json['cardCount'] as num).toInt(),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
  deletedAt: json['deletedAt'] as String?,
);

Map<String, dynamic> _$UserDeckToJson(UserDeck instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'subjectId': instance.subjectId,
  'color': instance.color,
  'sortOrder': instance.sortOrder,
  'cardCount': instance.cardCount,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'deletedAt': instance.deletedAt,
};
