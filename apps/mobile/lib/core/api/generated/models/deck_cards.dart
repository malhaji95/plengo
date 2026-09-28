// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_card.dart';
import 'student_deck.dart';

part 'deck_cards.g.dart';

@JsonSerializable()
class DeckCards {
  const DeckCards({
    required this.deck,
    required this.cards,
    required this.urlsExpireAt,
  });
  
  factory DeckCards.fromJson(Map<String, Object?> json) => _$DeckCardsFromJson(json);
  
  final StudentDeck deck;
  final List<StudentCard> cards;
  final String urlsExpireAt;

  Map<String, Object?> toJson() => _$DeckCardsToJson(this);
}
