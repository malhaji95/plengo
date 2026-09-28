// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentCard _$StudentCardFromJson(Map<String, dynamic> json) => StudentCard(
  id: json['id'] as String,
  deckId: json['deckId'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
  contentVersion: (json['contentVersion'] as num).toInt(),
  front: CardImage.fromJson(json['front'] as Map<String, dynamic>),
  back: CardImage.fromJson(json['back'] as Map<String, dynamic>),
);

Map<String, dynamic> _$StudentCardToJson(StudentCard instance) => <String, dynamic>{
  'id': instance.id,
  'deckId': instance.deckId,
  'sortOrder': instance.sortOrder,
  'contentVersion': instance.contentVersion,
  'front': instance.front,
  'back': instance.back,
};
