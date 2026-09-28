// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_card.dart';
import 'user_deck.dart';

part 'user_deck_cards.g.dart';

@JsonSerializable()
class UserDeckCards {
  const UserDeckCards({required this.deck, required this.cards, required this.urlsExpireAt});

  factory UserDeckCards.fromJson(Map<String, Object?> json) => _$UserDeckCardsFromJson(json);

  final UserDeck deck;
  final List<UserCard> cards;
  final String urlsExpireAt;

  Map<String, Object?> toJson() => _$UserDeckCardsToJson(this);
}
