// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'due_cards.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DueCards _$DueCardsFromJson(Map<String, dynamic> json) => DueCards(
  cards: (json['cards'] as List<dynamic>)
      .map((e) => DueCard.fromJson(e as Map<String, dynamic>))
      .toList(),
  userCards: (json['userCards'] as List<dynamic>)
      .map((e) => DueUserCard.fromJson(e as Map<String, dynamic>))
      .toList(),
  urlsExpireAt: json['urlsExpireAt'] as String,
);

Map<String, dynamic> _$DueCardsToJson(DueCards instance) => <String, dynamic>{
  'cards': instance.cards,
  'userCards': instance.userCards,
  'urlsExpireAt': instance.urlsExpireAt,
};
