// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'due_user_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DueUserCard _$DueUserCardFromJson(Map<String, dynamic> json) => DueUserCard(
  card: UserCard.fromJson(json['card'] as Map<String, dynamic>),
  deckName: json['deckName'] as String,
  state: SrsCardState.fromJson(json['state'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DueUserCardToJson(DueUserCard instance) => <String, dynamic>{
  'card': instance.card,
  'deckName': instance.deckName,
  'state': instance.state,
};
